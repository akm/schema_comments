# Generated by jeweler
# DO NOT EDIT THIS FILE DIRECTLY
# Instead, edit Jeweler::Tasks in Rakefile, and run 'rake gemspec'
# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = "schema_comments"
  s.version = "0.2.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["akimatter"]
  s.date = "2012-04-16"
  s.description = "schema_comments generates extra methods dynamically for attribute which has options"
  s.email = "akm2000@gmail.com"
  s.extra_rdoc_files = [
    "LICENSE.txt",
    "README.rdoc"
  ]
  s.files = [
    "Gemfile",
    "Gemfile.lock",
    "LICENSE.txt",
    "README.rdoc",
    "Rakefile",
    "VERSION",
    "autotest/discover.rb",
    "init.rb",
    "lib/annotate_models.rb",
    "lib/hash_key_orderable.rb",
    "lib/schema_comments.rb",
    "lib/schema_comments/base.rb",
    "lib/schema_comments/connection_adapters.rb",
    "lib/schema_comments/migration.rb",
    "lib/schema_comments/migrator.rb",
    "lib/schema_comments/schema.rb",
    "lib/schema_comments/schema_comment.rb",
    "lib/schema_comments/schema_dumper.rb",
    "lib/schema_comments/task.rb",
    "schema_comments.gemspec",
    "spec/.gitignore",
    "spec/annotate_models_spec.rb",
    "spec/database.yml",
    "spec/fake_app.rb",
    "spec/fixtures/.gitignore",
    "spec/hash_key_orderable_spec.rb",
    "spec/i18n_export_spec.rb",
    "spec/migration_spec.rb",
    "spec/migrations/valid/001_create_products.rb",
    "spec/migrations/valid/002_rename_products.rb",
    "spec/migrations/valid/003_rename_products_again.rb",
    "spec/migrations/valid/004_remove_price.rb",
    "spec/migrations/valid/005_change_products_name.rb",
    "spec/migrations/valid/006_change_products_name_with_comment.rb",
    "spec/migrations/valid/007_change_comments.rb",
    "spec/migrations/valid/008_create_users_without_comment.rb",
    "spec/rcov.opts",
    "spec/resources/models/product.rb",
    "spec/resources/models/product_name.rb",
    "spec/schema.rb",
    "spec/schema_comments/.gitignore",
    "spec/schema_comments/connection_adapters_spec.rb",
    "spec/schema_comments/schema_comment_spec.rb",
    "spec/schema_comments/schema_comments_broken_column_comments.yml",
    "spec/schema_comments/schema_comments_broken_column_hash.yml",
    "spec/schema_comments/schema_comments_broken_table_comments.yml",
    "spec/schema_comments/schema_comments_users_without_column_hash.yml",
    "spec/schema_comments/schema_dumper_spec.rb",
    "spec/spec.opts",
    "spec/spec_helper.rb",
    "spec/yaml_export_spec.rb",
    "tasks/annotate_models_tasks.rake",
    "tasks/schema_comments.rake"
  ]
  s.homepage = "http://github.com/akm/schema_comments"
  s.licenses = ["Ruby License"]
  s.require_paths = ["lib"]
  s.rubygems_version = "1.8.15"
  s.summary = "schema_comments generates extra methods dynamically"
  s.test_files = ["spec/annotate_models_spec.rb", "spec/fake_app.rb", "spec/hash_key_orderable_spec.rb", "spec/i18n_export_spec.rb", "spec/migration_spec.rb", "spec/migrations/valid/001_create_products.rb", "spec/migrations/valid/002_rename_products.rb", "spec/migrations/valid/003_rename_products_again.rb", "spec/migrations/valid/004_remove_price.rb", "spec/migrations/valid/005_change_products_name.rb", "spec/migrations/valid/006_change_products_name_with_comment.rb", "spec/migrations/valid/007_change_comments.rb", "spec/migrations/valid/008_create_users_without_comment.rb", "spec/resources/models/product.rb", "spec/resources/models/product_name.rb", "spec/schema.rb", "spec/schema_comments/connection_adapters_spec.rb", "spec/schema_comments/schema_comment_spec.rb", "spec/schema_comments/schema_dumper_spec.rb", "spec/spec_helper.rb", "spec/yaml_export_spec.rb", "spec/database.yml", "spec/human_readable_schema_comments.yml", "spec/schema_comments/schema_comments.yml", "spec/schema_comments/schema_comments_broken_column_comments.yml", "spec/schema_comments/schema_comments_broken_column_hash.yml", "spec/schema_comments/schema_comments_broken_table_comments.yml", "spec/schema_comments/schema_comments_users_without_column_hash.yml", "spec/schema_comments.yml"]

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<activesupport>, ["~> 3.1.0"])
      s.add_runtime_dependency(%q<activerecord>, ["~> 3.1.0"])
      s.add_development_dependency(%q<rspec>, ["~> 2.8.0"])
      s.add_development_dependency(%q<rspec-rails>, ["~> 2.8.1"])
      s.add_development_dependency(%q<yard>, ["~> 0.7"])
      s.add_development_dependency(%q<rdoc>, ["~> 3.12"])
      s.add_development_dependency(%q<bundler>, ["~> 1.0.0"])
      s.add_development_dependency(%q<jeweler>, ["~> 1.8.3"])
      s.add_development_dependency(%q<simplecov>, [">= 0"])
    else
      s.add_dependency(%q<activesupport>, ["~> 3.1.0"])
      s.add_dependency(%q<activerecord>, ["~> 3.1.0"])
      s.add_dependency(%q<rspec>, ["~> 2.8.0"])
      s.add_dependency(%q<rspec-rails>, ["~> 2.8.1"])
      s.add_dependency(%q<yard>, ["~> 0.7"])
      s.add_dependency(%q<rdoc>, ["~> 3.12"])
      s.add_dependency(%q<bundler>, ["~> 1.0.0"])
      s.add_dependency(%q<jeweler>, ["~> 1.8.3"])
      s.add_dependency(%q<simplecov>, [">= 0"])
    end
  else
    s.add_dependency(%q<activesupport>, ["~> 3.1.0"])
    s.add_dependency(%q<activerecord>, ["~> 3.1.0"])
    s.add_dependency(%q<rspec>, ["~> 2.8.0"])
    s.add_dependency(%q<rspec-rails>, ["~> 2.8.1"])
    s.add_dependency(%q<yard>, ["~> 0.7"])
    s.add_dependency(%q<rdoc>, ["~> 3.12"])
    s.add_dependency(%q<bundler>, ["~> 1.0.0"])
    s.add_dependency(%q<jeweler>, ["~> 1.8.3"])
    s.add_dependency(%q<simplecov>, [">= 0"])
  end
end

