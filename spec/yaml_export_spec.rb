# -*- coding: utf-8 -*-
require File.join(File.dirname(__FILE__), 'spec_helper')

describe SchemaComments::SchemaComment do

  before(:each) do
    SchemaComments.yaml_path = File.join(File.dirname(__FILE__), 'human_readable_schema_comments.yml')
    FileUtils.rm(SchemaComments.yaml_path, :verbose => true) if File.exist?(SchemaComments.yaml_path)

    (ActiveRecord::Base.connection.tables - IGNORED_TABLES).each do |t|
      ActiveRecord::Base.connection.drop_table(t) rescue nil
    end
    ActiveRecord::Base.connection.initialize_schema_migrations_table
    ActiveRecord::Base.connection.execute "DELETE FROM #{ActiveRecord::Migrator.schema_migrations_table_name}"
  end

  it "should export human readable yaml" do
    ActiveRecord::Schema.define(:version => 0) do
      create_table(:person, :comment => '人') do |t|
        t.string :name, :comment => '名前'
      end

      create_table(:addresses, :comment => '住所') do |t|
        t.integer :person_id, :comment => '人'
        t.text :descriptions, :comment => '記述'
      end

      create_table(:emails, :comment => 'メール') do |t|
        t.integer :person_id, :comment => '人'
        t.string :address, :comment => 'アドレス'
      end
    end

    expected = <<EOS
---
table_comments:
  addresses: "住所"
  emails: "メール"
  person: "人"
column_comments:
  addresses:
    person_id: "人"
    descriptions: "記述"
    id: "住所"
  emails:
    person_id: "人"
    address: "アドレス"
    id: "メール"
  person:
    name: "名前"
    id: "人"
EOS
    expected.gsub!('"', '') if Gem::Version.new(YAML::VERSION) >= Gem::Version.new("2.0.17")
    expect(File.read(SchemaComments.yaml_path)).to eq expected
  end

end
