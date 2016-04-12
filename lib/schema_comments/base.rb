module SchemaComments
  module Base
    def self.prepended(mod)
      mod.extend ClassMethods
      mod.ignore_pattern_to_export_i18n = /\[.*\]/
    end

    module ClassMethods
      def table_comment
        @table_comment ||= connection.table_comment(table_name)
      end

      def columns
        result = super
        unless @column_comments_loaded
          column_comment_hash = connection.column_comments(table_name)
          result.each do |column|
            column.comment = column_comment_hash[column.name.to_s]
          end
          @column_comments_loaded = true
        end
        result
      end

      def reset_column_comments
        @column_comments_loaded = false
      end

      def reset_table_comments
        @table_comment = nil
      end

      attr_accessor :ignore_pattern_to_export_i18n

      def export_i18n_models
        subclasses = ActiveRecord::Base.send(:subclasses).select do |klass|
          (klass != SchemaComments::SchemaComment) and
            klass.respond_to?(:table_exists?) and klass.table_exists?
        end
        subclasses.inject({}) do |d, m|
          comment = m.table_comment || ''
          comment.gsub!(ignore_pattern_to_export_i18n, '') if ignore_pattern_to_export_i18n
          d[m.name.underscore] = comment
          d
        end
      end

      def export_i18n_attributes(connection = ActiveRecord::Base.connection)
        subclasses = ActiveRecord::Base.send(:subclasses).select do |klass|
          (klass != SchemaComments::SchemaComment) and
            klass.respond_to?(:table_exists?) and klass.table_exists?
        end
        subclasses.inject({}) do |d, m|
          attrs = {}
          m.columns.each do |col|
            next if col.name == 'id'
            comment = (col.comment || '').dup
            comment.gsub!(ignore_pattern_to_export_i18n, '') if ignore_pattern_to_export_i18n
            attrs[col.name] = comment
          end
          d[m.name.underscore] = attrs
          d
        end
      end

    end

  end
end
