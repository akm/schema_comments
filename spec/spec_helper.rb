$KCODE='u'

ENV['RAILS_ENV'] ||= 'test'
unless defined?(RAILS_ENV)
  FIXTURES_ROOT = File.join(File.dirname(__FILE__), 'fixtures') unless defined?(FIXTURES_ROOT)

  RAILS_ENV = 'test' 
  RAILS_ROOT = File.dirname(__FILE__) unless defined?(RAILS_ROOT)

  require 'rubygems'
  require 'spec'

  require 'active_support'
  require 'active_record'
  # require 'action_mailer'
  require 'action_controller'
  require 'action_view'
  require 'initializer'

  require 'yaml'
  begin
    require 'yaml_waml'
  rescue
    $stderr.puts "yaml_waml not found. You should [sudo] gem install kakutani-yaml_waml"
  end

  config = YAML.load(IO.read(File.join(File.dirname(__FILE__), 'database.yml')))
  ActiveRecord::Base.logger = Logger.new(File.join(File.dirname(__FILE__), 'debug.log'))
  ActionController::Base.logger = ActiveRecord::Base.logger
  ActiveRecord::Base.establish_connection(config[ENV['DB'] || 'sqlite3'])


  load(File.join(File.dirname(__FILE__), 'schema.rb'))

  %w(resources/models).each do |path|
    $LOAD_PATH.unshift File.join(File.dirname(__FILE__), path)
    ActiveSupport::Dependencies.load_paths << File.join(File.dirname(__FILE__), path)
  end
  Dir.glob("resources/**/*.rb") do |filename|
    require filename
  end

  $LOAD_PATH << File.join(File.dirname(__FILE__), '..', 'lib')
  require File.join(File.dirname(__FILE__), '..', 'init')
end

