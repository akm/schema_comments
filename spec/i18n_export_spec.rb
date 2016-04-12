# -*- coding: utf-8 -*-
require File.join(File.dirname(__FILE__), 'spec_helper')

describe SchemaComments::Base do

  before(:each) do
    SchemaComments.yaml_path = File.expand_path(File.join(File.dirname(__FILE__), 'schema_comments.yml'))
    FileUtils.rm(SchemaComments.yaml_path, :verbose => true) if File.exist?(SchemaComments.yaml_path)

    (ActiveRecord::Base.connection.tables - IGNORED_TABLES).each do |t|
      ActiveRecord::Base.connection.drop_table(t) rescue nil
    end
    ActiveRecord::Base.connection.initialize_schema_migrations_table
    ActiveRecord::Base.connection.execute "DELETE FROM #{ActiveRecord::Migrator.schema_migrations_table_name}"
  end

  it "test_valid_migration" do
    expect(ActiveRecord::Base.connection.tables - %w(schema_migrations)).to eq []

    migration_path = File.join(MIGRATIONS_ROOT, 'valid')
    Dir.glob('*.rb').each do |file|
      require(file) if /^\d+?_.*/ =~ file
    end

    Product.reset_table_comments
    Product.reset_column_comments

    ActiveRecord::Migrator.up(migration_path, 1)
    expect(ActiveRecord::Migrator.current_version).to eq 1

    expect(ActiveRecord::Base.export_i18n_models.keys.include?('product')).to eq true
    expect(ActiveRecord::Base.export_i18n_models['product']).to eq '商品'

    expect(ActiveRecord::Base.export_i18n_attributes.keys.include?('product')).to eq true
    expect(ActiveRecord::Base.export_i18n_attributes['product']).to eq({
          'product_type_cd' => '種別コード',
          "price" => "価格",
          "name" => "商品名",
          "created_at" => "登録日時",
          "updated_at" => "更新日時"
        })
  end

end
