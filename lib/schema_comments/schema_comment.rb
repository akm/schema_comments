# -*- coding: utf-8 -*-
require 'yaml/store'
require 'hash_key_orderable'

module SchemaComments

  class SchemaComment

    TABLE_KEY = 'table_comments'
    COLUMN_KEY = 'column_comments'

    class << self
      def table_comment(table_name)
        @table_names ||= yaml_access{|db| db[TABLE_KEY]}.dup
        @table_names[table_name.to_s]
      end

      def column_comment(table_name, column_name)
        @column_names ||= yaml_access{|db| db[COLUMN_KEY] }.dup
        column_hash = @column_names[table_name.to_s] || {}
        column_hash[column_name.to_s]
      end

      def column_comments(table_name)
        result = nil
        @column_names ||= yaml_access{|db| db[COLUMN_KEY] }.dup
        result = @column_names[table_name.to_s]
        result || {}
      end

      def save_table_comment(table_name, comment)
        yaml_access do |db|
          db[TABLE_KEY][table_name.to_s] = comment
        end
        clear_cache
      end

      def save_column_comment(table_name, column_name, comment)
        yaml_access do |db|
          db[COLUMN_KEY][table_name.to_s] ||= {}
          db[COLUMN_KEY][table_name.to_s][column_name.to_s] = comment
        end
        clear_cache
      end

      def destroy_of(table_name, column_name)
        yaml_access do |db|
          column_hash = db[COLUMN_KEY][table_name.to_s]
          column_hash.delete(column_name.to_s) if column_hash
        end
        clear_cache
      end

      def update_table_name(table_name, new_name)
        yaml_access do |db|
          db[TABLE_KEY][new_name.to_s] = db[TABLE_KEY].delete(table_name.to_s)
          db[COLUMN_KEY][new_name.to_s] = db[COLUMN_KEY].delete(table_name.to_s)
        end
        clear_cache
      end

      def update_column_name(table_name, column_name, new_name)
        yaml_access do |db|
          table_cols = db[COLUMN_KEY][table_name.to_s]
          if table_cols
            table_cols[new_name.to_s] = table_cols.delete(column_name.to_s)
          end
        end
        clear_cache
      end

      def model_comments
        yaml_access{|db| db[TABLE_KEY] }.
          each_with_object({}){|(k,v),d| d[k.singularize] = v }
      end

      def attribute_comments
        yaml_access{|db| db[COLUMN_KEY] }.each_with_object({}) do |(k,v),d|
          d[k.singularize] = v.each_with_object({}) do |(name, comment), dd|
            dd[name.sub(/_id\z/, '')] = comment.sub(/id\z/i, '') if name =~ /_id\z/
            dd[name] = comment
          end
        end
      end

      def clear_cache
        @table_names = nil
        @column_names = nil
        self
      end

      def yaml_access(&block)
        if @yaml_transaction
          yield(@yaml_transaction) if block_given?
        else
          db = SortedStore.new(SchemaComments.yaml_path)
          result = nil
          # t = Time.now.to_f
          @yaml_transaction = db
          begin
            db.transaction do
              db[TABLE_KEY] ||= {}
              db[COLUMN_KEY] ||= {}
              SortedStore.validate_yaml!(db)
              result = yield(db) if block_given?
            end
          ensure
            @yaml_transaction = nil
          end
          # puts("SchemaComment#yaml_access %fms from %s" % [Time.now.to_f - t, caller[0].gsub(/^.+:in /, '')])
          result
        end
      end
    end

    class SortedStore < YAML::Store
      def dump(table)
        root = nil
        StringIO.open do |io|
          YAML.dump(@table, io)
          io.rewind
          root = YAML.load(io)
        end
        SortedStore.sort_yaml_content!(root)
        root.to_yaml(@opt)
      end

      def self.validate_yaml!(root)
        table_comments = (root['table_comments'] ||= {})
        column_comments = (root['column_comments'] ||= {})
        # raise YamlError, "Broken schame_comments.yml by invalid root: #{root.inspect}" unless root.is_a?(Hash)
        raise YamlError, "Broken schame_comments.yml by invalid table_comments" unless table_comments.is_a?(Hash)
        raise YamlError, "Broken schame_comments.yml by invalid_column_comments" unless column_comments.is_a?(Hash)
        column_comments.each do |table_name, value|
          next if value.nil?
          raise YamlError, "Broken schame_comments.yml by invalid column_comments for #{table_name}" unless value.is_a?(Hash)
        end
      end

      def self.sort_yaml_content!(root)
        self.validate_yaml!(root)
        table_comments = (root['table_comments'] ||= {})
        column_comments = (root['column_comments'] ||= {})
        # 大元は
        # table_comments:
        #   ...
        # column_comments:
        #   ...
        # その他
        #   ...
        # の順番です。
        root.extend(HashKeyOrderable)
        root.key_order = %w(table_comments column_comments)
        # table_comments はテーブル名のアルファベット順
        table_names = ActiveRecord::Base.connection.tables.sort - ['schema_migrations']
        table_comments.extend(HashKeyOrderable)
        table_comments.key_order = table_names
        # column_comments もテーブル名のアルファベット順
        column_comments.extend(HashKeyOrderable)
        column_comments.key_order = table_names
        # column_comments の各値はテーブルのカラム順
        conn = ActiveRecord::Base.connection
        columns_method = conn.respond_to?(:columns_without_schema_comments) ? :columns_without_schema_comments : :columns
        column_comments.each do |table_name, column_hash|
          column_hash ||= {}
          column_names = nil
          begin
            columns = conn.send(columns_method, table_name)
            column_names = columns.map(&:name)
          rescue ActiveRecord::ActiveRecordError
            column_names = column_hash.keys.sort
          end
          column_names.delete('id')
          raise YamlError, "Broken schame_comments.yml" unless column_hash.is_a?(Hash)
          column_hash.extend(HashKeyOrderable)
          column_hash.key_order = column_names
        end
      end
    end

  end
end
