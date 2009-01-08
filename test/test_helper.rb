$KCODE='u'
require 'test/unit'

FIXTURES_ROOT = File.join(File.dirname(__FILE__), 'fixtures') unless defined?(FIXTURES_ROOT)

require 'rubygems'
require 'active_support'
require 'active_record'
require 'active_record/fixtures'
require 'active_record/test_case'
require 'action_view'

require 'yaml'
config = YAML.load(IO.read(File.join(File.dirname(__FILE__), 'database.yml')))
ActiveRecord::Base.logger = Logger.new(File.join(File.dirname(__FILE__), 'debug.log'))
ActiveRecord::Base.establish_connection(config[ENV['DB'] || 'sqlite3'])

load(File.join(File.dirname(__FILE__), 'schema.rb'))

$LOAD_PATH << File.join(File.dirname(__FILE__), '..', 'lib')
require File.join(File.dirname(__FILE__), '..', 'init')

