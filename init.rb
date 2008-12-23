require 'schema_comments'

unless ActiveRecord::Base.ancestors.include?(SchemaComments::Base)
  class ActiveRecord::Base
    include SchemaComments::Base
  end
end

unless ActiveRecord::ConnectionAdapters::Column.ancestors.include?(SchemaComments::ConnectionAdapters::Column)
  module ActiveRecord::ConnectionAdapters
    class Column
      include SchemaComments::ConnectionAdapters::Column
    end

    class ColumnDefinition
      include SchemaComments::ConnectionAdapters::ColumnDefinition
    end

    class TableDefinition
      include SchemaComments::ConnectionAdapters::TableDefinition
    end

    class AbstractAdapter
      include SchemaComments::ConnectionAdapters::Adapter
    end

  end
end

# # %w(Mysql PostgreSQL SQLite3 SQLite Firebird DB2 Oracle Sybase Openbase Frontbase)
# %w(Mysql PostgreSQL SQLite3 SQLite).each do |adapter|
#   require "active_record/connection_adapters/#{adapter.downcase}_adapter"
#   ('ActiveRecord::ConnectionAdapters::' << "#{adapter}Adapter").constantize.module_eval do 
#     include SchemaComments::ConnectionAdapters::Adapter
#   end
# end
