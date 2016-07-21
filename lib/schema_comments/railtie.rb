require 'schema_comments'

require 'rails'

module SchemaScomments
  class Railtie < ::Rails::Railtie
    rake_tasks do
      SchemaComments.yaml_path = Rails.root.join("db/schema_comments.yml").to_s
      SchemaComments.setup
      require 'schema_comments/task'
    end
  end
end
