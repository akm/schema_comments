require 'active_support/core_ext/module'

require 'schema_comments/version'
require 'schema_comments/railtie'

module SchemaComments

  autoload :Base              , 'schema_comments/base'
  autoload :ConnectionAdapters, 'schema_comments/connection_adapters'
  autoload :Migration         , 'schema_comments/migration'
  autoload :Migrator          , 'schema_comments/migrator'
  autoload :Schema            , 'schema_comments/schema'
  autoload :SchemaComment     , 'schema_comments/schema_comment'
  autoload :SchemaDumper      , 'schema_comments/schema_dumper'

  mattr_accessor :yaml_path
  mattr_accessor :quiet

  class YamlError < StandardError
  end

  class << self
    def setup
      base_names = %w(Migration Migrator Schema) +
        %w(ColumnDefinition TableDefinition).map{|name| "ConnectionAdapters::#{name}"}

      base_names.each do |base_name|
        ar_class = "ActiveRecord::#{base_name}".constantize
        sc_class = "SchemaComments::#{base_name}".constantize
        unless ar_class.ancestors.include?(sc_class)
          ar_class.__send__(:prepend, sc_class)
        end
      end

      unless ActiveRecord::ConnectionAdapters::AbstractAdapter.ancestors.include?(SchemaComments::ConnectionAdapters::Adapter)
        ActiveRecord::ConnectionAdapters::AbstractAdapter.module_eval do
          prepend SchemaComments::ConnectionAdapters::Adapter
        end
      end

      # %w(Mysql PostgreSQL SQLite3 SQLite Firebird DB2 Oracle Sybase Openbase Frontbase)
      %w(Mysql Mysql2 PostgreSQL SQLite3 SQLite).each do |adapter|
        begin
          require("active_record/connection_adapters/#{adapter.downcase}_adapter")
          adapter_class = ('ActiveRecord::ConnectionAdapters::' << "#{adapter}Adapter").constantize
          adapter_class.module_eval do
            prepend SchemaComments::ConnectionAdapters::ConcreteAdapter
          end
        rescue Exception => e
        end
      end
    end

  end

end
