# -*- coding: utf-8 -*-

# see https://github.com/amatsuda/kaminari/blob/master/spec/fake_app.rb

require 'active_record'
require 'action_controller/railtie'
require 'action_view/railtie'

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
    raise e unless e.message =~ /^Mysql2?::Error: Can't create database/
  end
end

ActiveRecord::Base.configurations = configs
ActiveRecord::Base.establish_connection( db_name )

if RUBY_VERSION =~ /^1\.9\.2/
  # これは効かなかった
  # # http://rorguide.blogspot.jp/2011/06/incompatible-character-encodings-ascii.html
  # Encoding.default_external = Encoding::UTF_8
  # Encoding.default_internal = Encoding::UTF_8

  # http://koexuka.blogspot.jp/2010/03/rubyascii-8bit.html
  String.force_encoding("UTF-8")
end

# config
app = Class.new(Rails::Application)
app.config.secret_token = "3b7cd727ee24e8444053437c36cc66c4"
app.config.session_store :cookie_store, :key => "_myapp_session"
app.config.active_support.deprecation = :log
app.initialize!
