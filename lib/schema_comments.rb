module SchemaComments
  VERSION = '0.0.1'
  
  autoload :Base, 'schema_comments/base'
  autoload :ConnectionAdapters, 'schema_comments/connection_adapters'
  autoload :SchemaComment, 'schema_comments/schema_comment'
  autoload :SchemaDumper, 'schema_comments/schema_dumper'

  DEFAULT_YAML_PATH = File.expand_path(File.join(RAILS_ROOT, 'db/schema_comments.yml'))

  mattr_accessor :yaml_path
  self.yaml_path = DEFAULT_YAML_PATH
end
