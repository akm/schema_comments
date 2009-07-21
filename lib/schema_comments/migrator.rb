module SchemaComments
  module Migrator
    def self.included(mod)
      mod.extend(ClassMethods)
      mod.instance_eval do
        alias :migrate_without_schema_comments :migrate
        alias :migrate :migrate_with_schema_comments
      end
    end
    
    module ClassMethods
      def migrate_with_schema_comments(*args, &block)
        SchemaComments::SchemaComment.yaml_access do
          migrate_without_schema_comments(*args, &block)
        end
      end
    end
    
  end
end
