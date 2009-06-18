# -*- coding: utf-8 -*-
require File.join(File.dirname(__FILE__), 'spec_helper')

describe ActiveRecord::Migrator do

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
    Product.table_comment.should == '商品'
    {
      'product_type_cd' => '種別コード', 
      "price" => "価格",
      "name" => "商品名",
      "created_at" => "登録日時",
      "updated_at" => "更新日時"
    }.each do |col_name, comment|
      Product.columns.detect{|c| c.name.to_s == col_name}.comment.should == comment
    end
    
    ActiveRecord::Migrator.down(migration_path, 0)
    # SchemaComments::SchemaComment.count.should == 0
    
    ActiveRecord::Migrator.up(migration_path, 1)
    ActiveRecord::Migrator.up(migration_path, 2)
    ActiveRecord::Migrator.current_version.should == 2
    
    ProductName.table_comment.should == '商品'
    {
      'product_type_cd' => '種別コード', 
      "price" => "価格",
      "name" => "商品名",
      "created_at" => "登録日時",
      "updated_at" => "更新日時"
    }.each do |col_name, comment|
      ProductName.columns.detect{|c| c.name == col_name}.comment.should == comment
    end
    
    ActiveRecord::Migrator.down(migration_path, 1)
    ActiveRecord::Migrator.current_version.should == 1
    
    Product.table_comment.should == '商品'
    {
      'product_type_cd' => '種別コード', 
      "price" => "価格",
      "name" => "商品名",
      "created_at" => "登録日時",
      "updated_at" => "更新日時"
    }.each do |col_name, comment|
      Product.columns.detect{|c| c.name == col_name}.comment.should == comment
    end
    
    ActiveRecord::Migrator.up(migration_path, 4)
    ActiveRecord::Migrator.current_version.should == 4
    # SchemaComments::SchemaComment.count.should == 5
    
    ActiveRecord::Migrator.down(migration_path, 3)
    ActiveRecord::Migrator.current_version.should == 3
    # SchemaComments::SchemaComment.count.should == 6

    ActiveRecord::Migrator.up(migration_path, 5)
    ActiveRecord::Migrator.current_version.should == 5
    Product.columns.detect{|c| c.name == 'name'}.comment.should == '商品名'

    ActiveRecord::Migrator.up(migration_path, 6)
    ActiveRecord::Migrator.current_version.should == 6
    Product.reset_column_comments
    Product.columns.detect{|c| c.name == 'name'}.comment.should == '名称'
  end
  
end
