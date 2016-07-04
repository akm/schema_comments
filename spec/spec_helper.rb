require "simplecov"
SimpleCov.start

# Configure Rails Environment
ENV["RAILS_ENV"] = "test"

# Configure Rails Environment
ENV["DB"] ||= 'sqlite3' # "mysql2"

require File.expand_path("../../spec/dummy/config/environment.rb",  __FILE__)
ActiveRecord::Migrator.migrations_paths = [File.expand_path("../../spec/dummy/db/migrate", __FILE__)]

# Load support files
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each {|f| require f}

SchemaComments.setup

Dir.chdir(File.expand_path("../../spec/dummy",  __FILE__)) do
  system('RAILS_ENV=test bin/rake db:create')
end
