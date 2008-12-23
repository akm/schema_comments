module SchemaComments
  module Migration
    def self.included(mod)
      mod.extend(ClassMethods)
    end
    
    class CommentBuilder
      def initialize(migration, table)
        @migration, @table = migration, table
      end
      
      def comment(column, str)
        @migration.column_comment(@table, column, str)
      end
    end

    module ClassMethods
      def table_comment(table_name, comment, &block)
        comment = (comment[:comment] || comment['comment']) if comment.is_a?(Hash)
        ActiveRecord::Base.connection.table_comment(table_name, comment)
        if block_given?
          builder = CommentBuilder.new(self, table_name)
          yield(builder)
        end
      end

      def column_comment(table, column, comment)
        column_comments(table => {column => comment})
      end

      def table_comments(table_comments)
        table_comments.each do |table_name, comment|
          table_comment(table_name, comment)
        end
      end

      def column_comments(*args)
        ActiveRecord::Base.connection.column_comments(*args)
      end
    end
    
  end
end
