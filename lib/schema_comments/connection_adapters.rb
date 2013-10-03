# -*- coding: utf-8 -*-
module SchemaComments
  module ConnectionAdapters

    module Column
      attr_accessor :comment
    end

    module ColumnDefinition
      attr_accessor :comment
    end

    module TableDefinition
      def self.included(mod)
        mod.module_eval do
          alias_method_chain(:column, :schema_comments)
        end
      end
      attr_accessor :comment

      def column_with_schema_comments(name, type, options = {})
        column_without_schema_comments(name, type, options)
        column = self[name]
        column.comment = options[:comment]
        self
      end
    end

    module Adapter
      def column_comment(table_name, column_name, comment = nil) #:nodoc:
        if comment
          SchemaComment.save_column_comment(table_name, column_name, comment) unless SchemaComments.quiet
          return comment
        else
          SchemaComment.column_comment(table_name, column_name)
        end
      end

      # Mass assignment of comments in the form of a hash.  Example:
      #   column_comments(:users, {:first_name => "User's given name", :last_name => "Family name"})
      #   column_comments(:tags , {:id => "Tag IDentifier"})
      def column_comments(*args)
        case args.length
        when 1 then
           # こっちはSchemaComments::Base::ClassMethods#columns_with_schema_commentsから呼び出されます。
          return SchemaComment.column_comments(args.first)
        when 2 then
          if args.last.is_a?(Hash)
            # マイグレーションからActiveRecord関係を経由して呼び出されます。
            table_name = args.first.to_s
            args.last.each do |col, comment|
              column_comment(table_name, col, comment) unless SchemaComments.quiet
            end
            return
          end
        end
        raise ArgumentError, "#{self.class}#column_comments accepts (tabel_name) or (tabel_name, hash_col_comment)"
      end

      def table_comment(table_name, comment = nil) #:nodoc:
        if comment
          comment = (comment[:comment] || comment['comment']) if comment.is_a?(Hash)
          SchemaComment.save_table_comment(table_name, comment) unless SchemaComments.quiet
          return comment
        else
          SchemaComment.table_comment(table_name)
        end
      end

      def delete_schema_comments(table_name, column_name = nil)
        SchemaComment.destroy_of(table_name, column_name) unless SchemaComments.quiet
      end

      def update_schema_comments_table_name(table_name, new_name)
        SchemaComment.update_table_name(table_name, new_name) unless SchemaComments.quiet
      end

      def update_schema_comments_column_name(table_name, column_name, new_name)
        SchemaComment.update_column_name(table_name, column_name, new_name) unless SchemaComments.quiet
      end
    end

    module ConcreteAdapter
      def self.included(mod)
        mod.module_eval do
          alias_method_chain :columns      , :schema_comments
          alias_method_chain :create_table , :schema_comments
          alias_method_chain :drop_table   , :schema_comments
          alias_method_chain :rename_table , :schema_comments
          alias_method_chain :remove_column, :schema_comments
          alias_method_chain :add_column   , :schema_comments
          alias_method_chain :change_column, :schema_comments
          alias_method_chain :rename_column, :schema_comments
        end
      end

      #TODO: columnsメソッドに第二引数移行がないので本来は消すべき？
      def columns_with_schema_comments(table_name, name = nil, &block)
        result = columns_without_schema_comments(table_name)
        column_comment_hash = column_comments(table_name)
        result.each do |column|
          column.comment = column_comment_hash[column.name]
        end
        result
      end

      def create_table_with_schema_comments(table_name, options = {}, &block)
        table_def = nil
        result = create_table_without_schema_comments(table_name, options) do |t|
          table_def = t
          yield(t)
        end
        table_comment(table_name, options[:comment]) unless options[:comment].blank?
        table_def.columns.each do |col|
          column_comment(table_name, col.name, col.comment) unless col.comment.blank?
        end
        result
      end

      def drop_table_with_schema_comments(table_name, *args, &block)
        result = drop_table_without_schema_comments(table_name, *args)
        delete_schema_comments(table_name) unless @ignore_drop_table
        result
      end

      def rename_table_with_schema_comments(table_name, new_name)
        result = rename_table_without_schema_comments(table_name, new_name)
        update_schema_comments_table_name(table_name, new_name)
        result
      end

      def remove_column_with_schema_comments(table_name, *column_names)
        # sqlite3ではremove_columnがないので、以下のフローでスキーマ更新します。
        # 1. CREATE TEMPORARY TABLE "altered_xxxxxx" (・・・)
        # 2. PRAGMA index_list("xxxxxx")
        # 3. DROP TABLE "xxxxxx"
        # 4. CREATE TABLE "xxxxxx"
        # 5. PRAGMA index_list("altered_xxxxxx")
        # 6. DROP TABLE "altered_xxxxxx"
        #
        # このdrop tableの際に、schema_commentsを変更しないようにフラグを立てています。
        @ignore_drop_table = true
        remove_column_without_schema_comments(table_name, *column_names)
        column_names.each do |column_name|
          delete_schema_comments(table_name, column_name)
        end
      ensure
        @ignore_drop_table = false
      end

      def add_column_with_schema_comments(table_name, column_name, type, options = {})
        comment = options.delete(:comment)
        result = add_column_without_schema_comments(table_name, column_name, type, options)
        column_comment(table_name, column_name, comment) if comment
        result
      end

      def change_column_with_schema_comments(table_name, column_name, type, options = {})
        comment = options.delete(:comment)
        @ignore_drop_table = true
        result = change_column_without_schema_comments(table_name, column_name, type, options)
        column_comment(table_name, column_name, comment) if comment
        result
      ensure
        @ignore_drop_table = false
      end

      def rename_column_with_schema_comments(table_name, column_name, new_column_name)
        result = rename_column_without_schema_comments(table_name, column_name, new_column_name)
        comment = update_schema_comments_column_name(table_name, column_name, new_column_name)
        result
      end

    end
  end
end
