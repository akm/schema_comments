module SchemaComments
  module ConnectionAdapters
    # Add a @comment attribute to columns
    module Column
      attr_accessor :comment
    end
    
    # Sneak the comment in through the add_column_options! method when create_table is called with a block
    module ColumnDefinition
      # def self.included(mod)
      #   mod.module_eval do 
      #     alias_method_chain(:add_column_options!, :schema_comments)
      #   end
      # end
      
      attr_accessor :comment
      
      # private
      # def add_column_options_with_schema_comments!(sql, options)
      #   # add_column_options_without_schema_comments!(sql, options.merge(:comment => comment))
      #   add_column_options_without_schema_comments!(sql, options)
      # end
    end
    
    # Pass the comment through the TableDefinition
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
      def self.included(mod)
        mod.module_eval do 
          alias_method_chain :create_table, :schema_comments
          alias_method_chain :add_column_options!, :schema_comments
        end
      end
      
      # See also TableDefinition#column for details on how to create columns.
      def create_table_with_schema_comments(table_name, options = {}, &block)
        table_def = nil
        create_table_without_schema_comments(table_name, options) do |t|
          table_def = t
          yield(t)
        end
        table_comment(table_name, options[:comment]) unless options[:comment].blank?
        table_def.columns.each do |col|
          column_comment(table_name, col.name, col.comment) unless col.comment.blank?
        end
      end
      
      
      def columns(table_name, name = nil)#:nodoc:
        sql = "SHOW FULL FIELDS FROM #{table_name}"
        columns = []
        execute(sql, name).each { |field| columns << MysqlColumn.new(field[0], field[5], field[1], field[3] == "YES", field[8]) }
        columns
      end
      
      # Add an optional :comment to the options passed to change_column
      def add_column_options_with_schema_comments!(sql, options) #:nodoc:
        add_column_options_without_schema_comments!(sql, options)
        sql << " COMMENT #{quote(options[:comment])}" if options[:comment]
        #STDERR << "Column with options: #{sql}\n"
        sql
      end
      
      # Make sure we don't lose the comment when changing the name
      def rename_column(table_name, column_name, new_column_name, options = {}) #:nodoc:
        column_info = select_one("SHOW FULL FIELDS FROM #{table_name} LIKE '#{column_name}'")
        current_type = column_info["Type"]
        options[:comment] ||= column_info["Comment"]
        sql = "ALTER TABLE #{table_name} CHANGE #{column_name} #{new_column_name} #{current_type}"
        sql << " COMMENT #{quote(options[:comment])}" unless options[:comment].blank?
        execute sql
      end
      
      # Allow column comments to be explicitly set
      def column_comment(table_name, column_name, comment = nil) #:nodoc:
        if comment
          SchemaComment.save_column_comment(table_name, column_name, comment)
          return comment
        else
          SchemaComment.column_comment(table_name, column_name)
        end
      end
      
      # Mass assignment of comments in the form of a hash.  Example:
      #   column_comments {
      #     :users => {:first_name => "User's given name", :last_name => "Family name"},
      #     :tags  => {:id => "Tag IDentifier"}}
      def column_comments(contents)
        if contents.is_a?(Hash)
          contents.each_pair do |table, cols|
            cols.each_pair do |col, comment|
              column_comment(table, col, comment)
            end
          end
        else
          SchemaComment.column_comments(contents)
        end
      end
      
      def table_comment(table_name, comment = nil) #:nodoc:
        if comment
          SchemaComment.save_table_comment(table_name, comment)
          return comment
        else
          SchemaComment.table_comment(table_name)
        end
      end
    end
  end
end
