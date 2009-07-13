# -*- coding: utf-8 -*-
require 'yaml/store'

module SchemaComments
  # 現在はActiveRecord::Baseを継承していますが、将来移行が完全に終了した
  # 時点で、ActiveRecord::Baseの継承をやめます。
  #
  # それまではDBからのロードは可能ですが、YAMLにのみ保存します。
  class SchemaComment < ActiveRecord::Base
    set_table_name('schema_comments')

    TABLE_KEY = 'table_comments'
    COLUMN_KEY = 'column_comments'

    class << self
      def table_comment(table_name)
        if yaml_exist?
          @table_names ||= yaml_access{|db| db[TABLE_KEY]}.dup
          return @table_names[table_name.to_s]
        end
        return nil unless table_exists?
        connection.select_value(sanitize_conditions("select descriptions from schema_comments where table_name = '%s' and column_name is null" % table_name))
      end
      
      def column_comment(table_name, column_name)
        if yaml_exist?
          @column_names ||= yaml_access{|db| db[COLUMN_KEY] }.dup
          column_hash = @column_names[table_name.to_s] || {}
          return column_hash[column_name.to_s]
        end
        return nil unless table_exists?
        connection.select_value(sanitize_conditions("select descriptions from schema_comments where table_name = '%s' and column_name = '%s'" % [table_name, column_name]))
      end
      
      def column_comments(table_name)
        if yaml_exist?
          result = nil
          @column_names ||= yaml_access{|db| db[COLUMN_KEY] }.dup
          result = @column_names[table_name.to_s]
          return result || {}
        end
        return {} unless table_exists?
        hash_array = connection.select_all(sanitize_conditions("select column_name, descriptions from schema_comments where table_name = '%s' and column_name is not null" % table_name))
        hash_array.inject({}){|dest, r| dest[r['column_name']] = r['descriptions']; dest}
      end
      
      def save_table_comment(table_name, comment)
        yaml_access do |db|
          db[TABLE_KEY][table_name.to_s] = comment
        end
        @table_names = nil
      end
      
      def save_column_comment(table_name, column_name, comment)
        yaml_access do |db|
          db[COLUMN_KEY][table_name.to_s] ||= {}
          db[COLUMN_KEY][table_name.to_s][column_name.to_s] = comment
        end
        @column_names = nil
      end
      
      def destroy_of(table_name, column_name)
        yaml_access do |db|
          column_hash = db[COLUMN_KEY][table_name.to_s]
          column_hash.delete(column_name) if column_hash
        end
        @column_names = nil
      end
      
      def update_table_name(table_name, new_name)
        if yaml_exist?
          yaml_access do |db|
            db[TABLE_KEY][new_name.to_s] = db[TABLE_KEY].delete(table_name.to_s)
            db[COLUMN_KEY][new_name.to_s] = db[COLUMN_KEY].delete(table_name.to_s)
          end
        end
        @table_names = nil
        @column_names = nil
      end
      
      private
      
      def yaml_exist?
        File.exist?(SchemaComments.yaml_path)
      end
      
      def yaml_access(&block)
        db = YAML::Store.new(SchemaComments.yaml_path)
        result = nil
        t = Time.now.to_f
        db.transaction do
          db[TABLE_KEY] ||= {}
          db[COLUMN_KEY] ||= {}
          result = yield(db) if block_given?
        end
        # puts("SchemaComment#yaml_access %fms from %s" % [Time.now.to_f - t, caller[1].gsub(/^.+:in /, '')])
        result
      end

    end
  end
end
