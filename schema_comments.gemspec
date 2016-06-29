$:.push File.expand_path("../lib", __FILE__)
require "schema_comments/version"

Gem::Specification.new do |s|
  s.name        = "schema_comments"
  s.version     = SchemaComments::VERSION
  s.authors     = ["akm"]
  s.email       = ["akm2000@gmail.com"]
  s.homepage    = "http://github.com/akm/schema_comments"
  s.summary     = "schema_comments generates extra methods dynamically for attribute which has options."
  s.description = "schema_comments generates extra methods dynamically for attribute which has options."
  s.license     = "MIT"

  s.files       = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  # s.bindir      = "exe"
  # s.executables = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.test_files = Dir["test/**/*"]

  s.add_runtime_dependency('activesupport', ">= 4.0.0")
  s.add_runtime_dependency('activerecord', ">= 4.0.0")

  s.add_development_dependency "bundler"
  s.add_development_dependency "rake"
  s.add_development_dependency "rspec"
end
