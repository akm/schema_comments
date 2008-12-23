module SchemaComments
  module Base
    def self.included(mod)
      mod.extend ClassMethods
      mod.instance_eval do
        alias :columns_without_schema_comments :columns
        alias :columns :columns_with_schema_comments
      end
    end
    
    module ClassMethods
      def table_comment
        @table_comment ||= connection.table_comment(table_name)
      end

      def columns_with_schema_comments
        result = columns_without_schema_comments
        unless @column_comments_loaded
          column_comment_hash = connection.column_comments(table_name)
          result.each do |column|
            column.comment = column_comment_hash[column.name]
          end
          @column_comments_loaded = true
        end
        result
      end
    end
  end
end
