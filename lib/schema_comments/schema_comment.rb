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
      
      def update_column_name(table_name, column_name, new_name)
        if yaml_exist?
          yaml_access do |db|
            table_cols = db[COLUMN_KEY][table_name.to_s]
            if table_cols
              table_cols[new_name.to_s] = table_cols.delete(column_name.to_s)
            end
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
        db = SortedStore.new(SchemaComments.yaml_path)
        result = nil
        # t = Time.now.to_f
        db.transaction do
          db[TABLE_KEY] ||= {}
          db[COLUMN_KEY] ||= {}
          result = yield(db) if block_given?
        end
        # puts("SchemaComment#yaml_access %fms from %s" % [Time.now.to_f - t, caller[1].gsub(/^.+:in /, '')])
        result
      end

    end

    class SortedStore < YAML::Store
      module ColumnNamedHash
        def each
          @column_names.each do |column_name|
            yield(column_name, self[column_name])
          end
        end
      end

      def dump(table)
        root = nil
        StringIO.open do |io|
          YAML.dump(@table, io)
          io.rewind
          root = YAML.load(io)
        end

        table_comments = root['table_comments']
        column_comments = root['column_comments']
        # 大元は
        # table_comments:
        #   ...
        # column_comments:
        #   ...
        # その他
        #   ...
        # の順番です。
        root.instance_eval do
          def each
            yield('table_comments', self['table_comments'])
            yield('column_comments', self['column_comments'])
            (self.keys - ['table_comments', 'column_comments']).each do |key|
              yield(key, self[key])
            end
          end
        end
        # table_comments はテーブル名のアルファベット順
        table_names = ActiveRecord::Base.connection.tables.sort - ['schema_migrations']
        table_comments.instance_variable_set(:@table_names, table_names)
        table_comments.instance_eval do
          def each
            @table_names.each do |key|
              yield(key, self[key])
            end
          end
        end
        # column_comments もテーブル名のアルファベット順
        column_comments.instance_variable_set(:@table_names, table_names)
        column_comments.instance_eval do
          def each
            @table_names.each do |key|
              yield(key, self[key])
            end
          end
        end
        # column_comments の各値はテーブルのカラム順
        column_comments.each do |table_name, column_hash|
          column_names = nil
          begin
            columns = ActiveRecord::Base.connection.columns_without_schema_comments(table_name, "#{table_name.classify} Columns")
            column_names = columns.map(&:name)
          rescue ActiveRecord::ActiveRecordError
            column_names = column_hash.keys.sort
          end
          column_names.delete('id')
          column_hash.instance_variable_set(:@column_names, column_names)
          column_hash.extend(ColumnNamedHash)
        end
        root.to_yaml(@opt)
      end
    end

  end
end
