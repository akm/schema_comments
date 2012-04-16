# encoding: utf-8

require 'rubygems'
require 'bundler'
begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end
require 'rake'

require 'jeweler'
Jeweler::Tasks.new do |gem|
  # gem is a Gem::Specification... see http://docs.rubygems.org/read/chapter/20 for more options
  gem.name = "schema_comments"
  gem.homepage = "http://github.com/akm/schema_comments"
  gem.license = "Ruby License"
  gem.summary  = "schema_comments generates extra methods dynamically"
  gem.description  = "schema_comments generates extra methods dynamically for attribute which has options"
  gem.email = "akm2000@gmail.com"
  gem.authors = ["akimatter"]
  # gem is a Gem::Specification... see http://www.rubygems.org/read/chapter/20 for additional settings
  gem.test_files = Dir.glob('spec/**/*.rb') + Dir.glob('spec/**/*.yml')
  # dependencies defined in Gemfile
end
Jeweler::RubygemsDotOrgTasks.new

require 'rspec/core'
require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec) do |spec|
  spec.pattern = FileList['spec/**/*_spec.rb']
end

RSpec::Core::RakeTask.new(:rcov) do |spec|
  spec.pattern = 'spec/**/*_spec.rb'
  spec.rcov = true
end

task :default => :spec

require 'yard'
YARD::Rake::YardocTask.new
