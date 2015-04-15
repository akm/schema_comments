# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'schema_comments/version'

Gem::Specification.new do |spec|
  spec.name          = "schema_comments"
  spec.version       = SchemaComments::VERSION
  spec.authors       = ["akm"]
  spec.email         = ["akm2000@gmail.com"]

  spec.summary       = %q{schema_comments generates extra methods dynamically for attribute which has options.}
  spec.description   = %q{schema_comments generates extra methods dynamically for attribute which has options.}
  spec.homepage      = "http://github.com/akm/schema_comments"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency('activesupport', ">= 4.0.0")
  spec.add_runtime_dependency('activerecord', ">= 4.0.0")

  spec.add_development_dependency "bundler", "~> 1.9"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec"
end
