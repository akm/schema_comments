require 'active_support/core_ext/module'

require 'schema_comments/railtie'

module SchemaComments
  VERSION = File.read(File.expand_path("../../VERSION", __FILE__))

  autoload :Base              , 'schema_comments/base'
  autoload :ConnectionAdapters, 'schema_comments/connection_adapters'
  autoload :Migration         , 'schema_comments/migration'
  autoload :Migrator          , 'schema_comments/migrator'
  autoload :Schema            , 'schema_comments/schema'
  autoload :SchemaComment     , 'schema_comments/schema_comment'
  autoload :SchemaDumper      , 'schema_comments/schema_dumper'

  mattr_accessor :yaml_path
  self.yaml_path = Rails.root.join("db/schema_comments.yml").to_s if defined?(Rails) && Rails.root

  mattr_accessor :quiet

  class YamlError < StandardError
  end

  class << self
    def setup
      base_names = %w(Base Migration Migrator Schema) +
        %w(Column ColumnDefinition TableDefinition).map{|name| "ConnectionAdapters::#{name}"}

      base_names.each do |base_name|
        ar_class = "ActiveRecord::#{base_name}".constantize
        sc_class = "SchemaComments::#{base_name}".constantize
        unless ar_class.ancestors.include?(sc_class)
          ar_class.__send__(:include, sc_class)
        end
      end

      unless ActiveRecord::ConnectionAdapters::AbstractAdapter.ancestors.include?(SchemaComments::ConnectionAdapters::Adapter)
        ActiveRecord::ConnectionAdapters::AbstractAdapter.module_eval do
          include SchemaComments::ConnectionAdapters::Adapter
        end
      end

      # %w(Mysql PostgreSQL SQLite3 SQLite Firebird DB2 Oracle Sybase Openbase Frontbase)
      %w(Mysql Mysql2 PostgreSQL SQLite3 SQLite).each do |adapter|
        begin
          require("active_record/connection_adapters/#{adapter.downcase}_adapter")
          adapter_class = ('ActiveRecord::ConnectionAdapters::' << "#{adapter}Adapter").constantize
          adapter_class.module_eval do
            include SchemaComments::ConnectionAdapters::ConcreteAdapter
          end
        rescue Exception => e
        end
      end
    end

  end

end
