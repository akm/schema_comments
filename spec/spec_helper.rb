require "simplecov"
SimpleCov.start do
  add_filter "/spec/"
end

# Configure Rails Environment
ENV["RAILS_ENV"] = "test"

# Configure Rails Environment
ENV["DB"] ||= 'sqlite3' # "mysql2"

require File.expand_path("../dummy/config/environment.rb",  __FILE__)
ActiveRecord::Migrator.migrations_paths = [File.expand_path("../dummy/db/migrate", __FILE__)]

# Load support files
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each {|f| require f}

SchemaComments.setup

# Dir.chdir(File.expand_path("../dummy",  __FILE__)) do
#   system('RAILS_ENV=test bin/rake db:create')
# end

ActiveRecord::Tasks::DatabaseTasks.create_current
