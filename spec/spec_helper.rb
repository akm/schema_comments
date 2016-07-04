require "simplecov"
SimpleCov.start

# Configure Rails Environment
ENV["RAILS_ENV"] = "test"

# Configure Rails Environment
ENV["DB"] ||= 'sqlite3' # "mysql2"

dummy_path =
  (Gem.loaded_specs['rails'].version >= Gem::Version.new('5.0.0')) ?
    'spec/dummy4rails5' : 'spec/dummy'

require File.expand_path("../../#{dummy_path}/config/environment.rb",  __FILE__)
ActiveRecord::Migrator.migrations_paths = [File.expand_path("../../#{dummy_path}/db/migrate", __FILE__)]

# Load support files
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each {|f| require f}

SchemaComments.setup
