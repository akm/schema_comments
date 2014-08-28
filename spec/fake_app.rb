# -*- coding: utf-8 -*-

# see https://github.com/amatsuda/kaminari/blob/master/spec/fake_app.rb

require 'active_record'
require 'action_controller/railtie'
require 'action_view/railtie'
require 'yaml'

# database
db_name = ENV['DB'] || 'sqlite3'
configs = YAML.load_file(File.expand_path("../database.yml", __FILE__))
config = configs[db_name]

def mysql_creation_options(config)
  @charset   = ENV['CHARSET']   || 'utf8'
  @collation = ENV['COLLATION'] || 'utf8_unicode_ci'
  {:charset => (config['charset'] || @charset), :collation => (config['collation'] || @collation)}
end

case db_name
when /mysql/ then
  ActiveRecord::Base.establish_connection(config.merge('database' => nil))
  begin
    ActiveRecord::Base.connection.create_database(config['database'], mysql_creation_options(config))
  rescue ActiveRecord::StatementInvalid => e
    raise e unless e.message =~ /^Mysql2?::Error: Can't create database|^ActiveRecord::JDBCError: Can't create database/
  end
end

ActiveRecord::Base.configurations = configs
ActiveRecord::Base.establish_connection( db_name )

# config
app = Class.new(Rails::Application)
app.config.secret_token = "3b7cd727ee24e8444053437c36cc66c4"
app.config.session_store :cookie_store, :key => "_myapp_session"
app.config.active_support.deprecation = :log
app.initialize!
