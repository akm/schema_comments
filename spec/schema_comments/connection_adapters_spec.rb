# -*- coding: utf-8 -*-
require File.join(File.dirname(__FILE__), '../spec_helper')

describe SchemaComments::ConnectionAdapters do

  before(:each) do
    Product.reset_column_information

    SchemaComments.yaml_path = File.expand_path(File.join(File.dirname(__FILE__), 'schema_comments.yml'))
    FileUtils.rm(SchemaComments.yaml_path, :verbose => true) if File.exist?(SchemaComments.yaml_path)

    (ActiveRecord::Base.connection.tables - IGNORED_TABLES).each do |t|
      ActiveRecord::Base.connection.drop_table(t) rescue nil
    end
    ActiveRecord::Base.connection.initialize_schema_migrations_table
    ActiveRecord::Base.connection.execute "DELETE FROM #{ActiveRecord::Migrator.schema_migrations_table_name}"

    expect(ActiveRecord::Base.connection.tables - %w(schema_migrations)).to eq []

    migration_path = File.join(MIGRATIONS_ROOT, 'valid')
    Dir.glob('*.rb').each do |file|
      require(file) if /^\d+?_.*/ =~ file
    end

    expect(ActiveRecord::Base.connection.tables).to eq ['schema_migrations']

    Product.reset_table_comments
    Product.reset_column_comments

    ActiveRecord::Migrator.up(migration_path, 1)
    expect(ActiveRecord::Migrator.current_version).to eq 1

    expect(ActiveRecord::Base.connection.tables).to match_array ['schema_migrations', 'products']

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

  describe SchemaComments::ConnectionAdapters::Column do
    describe :comment do
      it "should return comment" do
        expect(Product.columns.detect{|c| c.name == "product_type_cd"}.comment).to eq '種別コード'
        expect(Product.columns.detect{|c| c.name == "price"}.comment).to eq '価格'
        expect(Product.columns.detect{|c| c.name == "name"}.comment).to eq '商品名'
        expect(Product.columns.detect{|c| c.name == "created_at"}.comment).to eq '登録日時'
        expect(Product.columns.detect{|c| c.name == "updated_at"}.comment).to eq '更新日時'
      end
    end

  end
end
