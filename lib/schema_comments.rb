module SchemaComments
  VERSION = '0.0.1'
  
  autoload :Base, 'schema_comments/base'
  autoload :ConnectionAdapters, 'schema_comments/connection_adapters'
  autoload :SchemaComment, 'schema_comments/schema_comment'
  autoload :SchemaDumper, 'schema_comments/schema_dumper'
  
end
