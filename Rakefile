# encoding: utf-8

require 'rubygems'
require 'rake'
# require 'rubygems/package_task'
require 'bundler'
require "bundler/gem_tasks"

require 'rspec/core'
require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec) do |spec|
  spec.pattern = FileList['spec/**/*_spec.rb']
end

task :default => :spec
task :test => :spec # for rubygems-test

require 'yard'
YARD::Rake::YardocTask.new
