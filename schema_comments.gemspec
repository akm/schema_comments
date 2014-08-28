# -*- encoding: utf-8 -*-

version = File.read(File.expand_path("../VERSION", __FILE__)).strip

Gem::Specification.new do |s|
  s.name = "schema_comments"
  s.version = version

  s.required_rubygems_version = Gem::Requirement.new("> 1.3.1") if s.respond_to? :required_rubygems_version=
  s.authors = ["akimatter"]
  # s.date = "2012-04-18"
  s.description = "schema_comments generates extra methods dynamically for attribute which has options"
  s.email = "akm2000@gmail.com"
  s.extra_rdoc_files = [
    "LICENSE.txt",
    "README.md"
  ]
  s.files = Dir[".rspec", "Gemfile", "Gemfile.lock", "LICENSE.txt", "README.rdoc",
    "VERSION", "init.rb", "lib/**/*", "tasks/**/*" ]

  s.homepage = "http://github.com/akm/schema_comments"
  s.licenses = ["Ruby License"]
  s.require_paths = ["lib"]
  s.rubygems_version = "1.8.15"
  s.summary = "schema_comments generates extra methods dynamically"
  s.test_files = Dir["spec/**/*.rb", "spec/**/*.yml"]

  s.add_runtime_dependency('activesupport', ">= 3.0.0")
  s.add_runtime_dependency('activerecord', ">= 3.0.0")

  s.add_development_dependency('bundler')
  s.add_development_dependency('rake')
  s.add_development_dependency('rspec', "~> 2.10.0")
  s.add_development_dependency('rspec-rails', "~> 2.10.1")
  s.add_development_dependency('yard')
end
