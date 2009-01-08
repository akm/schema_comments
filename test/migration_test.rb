# -*- coding: utf-8 -*-
require File.join(File.dirname(__FILE__), 'test_helper')

MIGRATIONS_ROOT = File.join(File.dirname(__FILE__), 'migrations')

class MigrationTest < Test::Unit::TestCase

  class Product < ActiveRecord::Base; end
  class ProductName < ActiveRecord::Base; end

  IGNORED_TABLES = %w(schema_migrations)
  
  def setup
    (ActiveRecord::Base.connection.tables - IGNORED_TABLES).each do |t|
      ActiveRecord::Base.connection.drop_table(t) rescue nil
    end
    ActiveRecord::Base.connection.initialize_schema_migrations_table
    ActiveRecord::Base.connection.execute "DELETE FROM #{ActiveRecord::Migrator.schema_migrations_table_name}"
  end
  
  def test_valid_migration
    assert_equal [], ActiveRecord::Base.connection.tables - %w(schema_migrations)
    
    migration_path = File.join(MIGRATIONS_ROOT, 'valid')
    Dir.glob('*.rb').each do |file|
      require(file) if /^\d+?_.*/ =~ file
    end
    
    ActiveRecord::Migrator.up(migration_path, 1)

    assert_equal 1, ActiveRecord::Migrator.current_version
    assert_equal '商品', Product.table_comment
    {
      'product_type_cd' => '種別コード', 
      "price" => "価格",
      "name" => "商品名",
      "created_at" => "登録日時",
      "updated_at" => "更新日時"
    }.each do |col_name, comment|
      assert_equal comment, Product.columns.detect{|c| c.name == col_name}.comment
    end
    
    ActiveRecord::Migrator.down(migration_path, 0)
    assert_equal 0, SchemaComments::SchemaComment.count
    
    ActiveRecord::Migrator.up(migration_path, 1)
    ActiveRecord::Migrator.up(migration_path, 2)
    assert_equal 2, ActiveRecord::Migrator.current_version
    
    assert_equal '商品', ProductName.table_comment
    {
      'product_type_cd' => '種別コード', 
      "price" => "価格",
      "name" => "商品名",
      "created_at" => "登録日時",
      "updated_at" => "更新日時"
    }.each do |col_name, comment|
      assert_equal comment, ProductName.columns.detect{|c| c.name == col_name}.comment
    end
    
    ActiveRecord::Migrator.down(migration_path, 1)
    assert_equal 1, ActiveRecord::Migrator.current_version
    
    assert_equal '商品', Product.table_comment
    {
      'product_type_cd' => '種別コード', 
      "price" => "価格",
      "name" => "商品名",
      "created_at" => "登録日時",
      "updated_at" => "更新日時"
    }.each do |col_name, comment|
      assert_equal comment, Product.columns.detect{|c| c.name == col_name}.comment
    end
    
    ActiveRecord::Migrator.up(migration_path, 4)
    assert_equal 4, ActiveRecord::Migrator.current_version
    assert_equal 5, SchemaComments::SchemaComment.count
    
    ActiveRecord::Migrator.down(migration_path, 3)
    assert_equal 3, ActiveRecord::Migrator.current_version
    assert_equal 6, SchemaComments::SchemaComment.count

    ActiveRecord::Migrator.up(migration_path, 5)
    assert_equal 5, ActiveRecord::Migrator.current_version
    assert_equal '商品名', Product.columns.detect{|c| c.name == 'name'}.comment

    ActiveRecord::Migrator.up(migration_path, 6)
    assert_equal 6, ActiveRecord::Migrator.current_version
    Product.reset_column_comments
    assert_equal '名称', Product.columns.detect{|c| c.name == 'name'}.comment
  end
  
end
