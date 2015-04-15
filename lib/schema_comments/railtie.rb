require 'schema_comments'

require 'rails'

module SchemaScomments
  class Railtie < ::Rails::Railtie
    rake_tasks do
      require 'schema_comments/task'
    end
  end
end
