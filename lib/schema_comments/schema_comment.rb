# -*- coding: utf-8 -*-
require 'yaml/store'
require 'hash_key_orderable'

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
puts "#{__FILE__}##{__LINE__}"
        @table_names ||= yaml_access{|db| db[TABLE_KEY]}.dup
        @table_names[table_name.to_s]
      end

      def column_comment(table_name, column_name)
puts "#{__FILE__}##{__LINE__}"
        @column_names ||= yaml_access{|db| db[COLUMN_KEY] }.dup
        column_hash = @column_names[table_name.to_s] || {}
        column_hash[column_name.to_s]
      end

      def column_comments(table_name)
puts "#{__FILE__}##{__LINE__}"
        result = nil
        @column_names ||= yaml_access{|db| db[COLUMN_KEY] }.dup
        result = @column_names[table_name.to_s]
        result || {}
      end

      def save_table_comment(table_name, comment)
puts "#{__FILE__}##{__LINE__}"
        yaml_access do |db|
          db[TABLE_KEY][table_name.to_s] = comment
        end
        @table_names = nil
      end

      def save_column_comment(table_name, column_name, comment)
puts "#{__FILE__}##{__LINE__}"
        yaml_access do |db|
          db[COLUMN_KEY][table_name.to_s] ||= {}
          db[COLUMN_KEY][table_name.to_s][column_name.to_s] = comment
        end
        @column_names = nil
      end

      def destroy_of(table_name, column_name)
puts "#{__FILE__}##{__LINE__}"
        yaml_access do |db|
          column_hash = db[COLUMN_KEY][table_name.to_s]
          column_hash.delete(column_name) if column_hash
        end
        @column_names = nil
      end

      def update_table_name(table_name, new_name)
puts "#{__FILE__}##{__LINE__}"
        yaml_access do |db|
          db[TABLE_KEY][new_name.to_s] = db[TABLE_KEY].delete(table_name.to_s)
          db[COLUMN_KEY][new_name.to_s] = db[COLUMN_KEY].delete(table_name.to_s)
        end
        @table_names = nil
        @column_names = nil
      end

      def update_column_name(table_name, column_name, new_name)
puts "#{__FILE__}##{__LINE__}"
        yaml_access do |db|
          table_cols = db[COLUMN_KEY][table_name.to_s]
          if table_cols
            table_cols[new_name.to_s] = table_cols.delete(column_name.to_s)
          end
        end
        @table_names = nil
        @column_names = nil
      end

      def yaml_exist?
        File.exist?(SchemaComments.yaml_path)
      end

      def yaml_access(&block)
puts "#{__FILE__}##{__LINE__}"
        if @yaml_transaction
          yield(@yaml_transaction) if block_given?
        else
          db = SortedStore.new(SchemaComments.yaml_path)
          result = nil
          # t = Time.now.to_f
          db.transaction do
            @yaml_transaction = db
            begin
              db[TABLE_KEY] ||= {}
              db[COLUMN_KEY] ||= {}
              result = yield(db) if block_given?
            ensure
              @yaml_transaction = nil
            end
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
        table_comments = root['table_comments'] || {}
        column_comments = root['column_comments'] || {}
        # 大元は
        # table_comments:
        #   ...
        # column_comments:
        #   ...
        # その他
        #   ...
        # の順番です。
        raise YamlError, "Broken schame_comments.yml" unless root.is_a?(Hash)
        root.extend(HashKeyOrderable)
        root.key_order = %w(table_comments column_comments)
        # table_comments はテーブル名のアルファベット順
        table_names = ActiveRecord::Base.connection.tables.sort - ['schema_migrations']
        raise YamlError, "Broken schame_comments.yml" unless table_comments.is_a?(Hash)
        table_comments.extend(HashKeyOrderable)
        table_comments.key_order = table_names
        # column_comments もテーブル名のアルファベット順
        raise YamlError, "Broken schame_comments.yml" unless column_comments.is_a?(Hash)
        column_comments.extend(HashKeyOrderable)
        column_comments.key_order = table_names
        # column_comments の各値はテーブルのカラム順
        column_comments.each do |table_name, column_hash|
          column_hash ||= {}
          column_names = nil
          begin
            columns = ActiveRecord::Base.connection.columns_without_schema_comments(table_name, "#{table_name.classify} Columns")
            column_names = columns.map(&:name)
          rescue ActiveRecord::ActiveRecordError
            column_names = column_hash.keys.sort
          end
          column_names.delete('id')
          raise YamlError, "Broken schame_comments.yml" unless column_hash.is_a?(Hash)
          column_hash.extend(HashKeyOrderable)
          column_hash.key_order = column_names
        end
        root.to_yaml(@opt)
      end
    end

  end
end
