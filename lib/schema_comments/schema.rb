module SchemaComments
  module Schema
    def self.included(mod)
      mod.extend(ClassMethods)
      mod.instance_eval do
        alias :define_without_schema_comments :define
        alias :define :define_with_schema_comments
      end
    end

    module ClassMethods
      def define_with_schema_comments(*args, &block)
        SchemaComments::SchemaComment.yaml_access do
          define_without_schema_comments(*args, &block)
        end
      end
    end

  end
end
