module SchemaComments
  module Migration
    def self.prepended(mod)
      mod.singleton_class.prepend(ClassMethods)
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
