unless ENV['SCHEMA_COMMENTS_DISABLED']

  require 'schema_comments'

  base_names = %w(Base Migration Migrator Schema SchemaDumper) +
    %w(Column ColumnDefinition TableDefinition).map{|name| "ConnectionAdapters::#{name}"}

  base_names.each do |base_name|
    ar_class = "ActiveRecord::#{base_name}".constantize
    sc_class = "SchemaComments::#{base_name}".constantize
    unless ar_class.ancestors.include?(sc_class)
      ar_class.__send__(:include, sc_class)
    end
  end

  unless ActiveRecord::ConnectionAdapters::AbstractAdapter.ancestors.include?(SchemaComments::ConnectionAdapters::Adapter)
    class ActiveRecord::ConnectionAdapters::AbstractAdapter
      include SchemaComments::ConnectionAdapters::Adapter
    end
  end

  # %w(Mysql PostgreSQL SQLite3 SQLite Firebird DB2 Oracle Sybase Openbase Frontbase)
  %w(Mysql PostgreSQL SQLite3 SQLite).each do |adapter|
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
