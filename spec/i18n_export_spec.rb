# -*- coding: utf-8 -*-
require File.join(File.dirname(__FILE__), 'spec_helper')

describe SchemaComments::Base do

  MIGRATIONS_ROOT = File.join(File.dirname(__FILE__), 'migrations')

  IGNORED_TABLES = %w(schema_migrations)
  
  before(:each) do
    SchemaComments.yaml_path = File.expand_path(File.join(File.dirname(__FILE__), 'schema_comments.yml'))

    (ActiveRecord::Base.connection.tables - IGNORED_TABLES).each do |t|
      ActiveRecord::Base.connection.drop_table(t) rescue nil
    end
    ActiveRecord::Base.connection.initialize_schema_migrations_table
    ActiveRecord::Base.connection.execute "DELETE FROM #{ActiveRecord::Migrator.schema_migrations_table_name}"
  end
  
  it "test_valid_migration" do
    (ActiveRecord::Base.connection.tables - %w(schema_migrations)).should == []
    
    migration_path = File.join(MIGRATIONS_ROOT, 'valid')
    Dir.glob('*.rb').each do |file|
      require(file) if /^\d+?_.*/ =~ file
    end
    
    Product.reset_table_comments
    Product.reset_column_comments

    ActiveRecord::Migrator.up(migration_path, 1)
    ActiveRecord::Migrator.current_version.should == 1
    
    ActiveRecord::Base.export_i18n_models.keys.include?('product').should == true
    ActiveRecord::Base.export_i18n_models['product'].should == '商品'
    
    ActiveRecord::Base.export_i18n_attributes.keys.include?('product').should == true
    ActiveRecord::Base.export_i18n_attributes['product'].should == {
          'product_type_cd' => '種別コード', 
          "price" => "価格",
          "name" => "商品名",
          "created_at" => "登録日時",
          "updated_at" => "更新日時"
        }
  end
  
end