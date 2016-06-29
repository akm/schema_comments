require "simplecov"
SimpleCov.start

# Configure Rails Environment
ENV["RAILS_ENV"] = "test"

require File.expand_path("../../test/dummy/config/environment.rb",  __FILE__)
ActiveRecord::Migrator.migrations_paths = [File.expand_path("../../test/dummy/db/migrate", __FILE__)]
require "rails/test_help"

# Load support files
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each {|f| require f}

SchemaComments.setup
