module SchemaComments
  module Migrator
    def self.prepend(mod)
      mod.extend(ClassMethods)
    end

    module ClassMethods
      def migrate(*args, &block)
        SchemaComments::SchemaComment.yaml_access do
          super(*args, &block)
        end
      end
    end

  end
end
