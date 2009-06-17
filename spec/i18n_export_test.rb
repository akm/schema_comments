# -*- coding: utf-8 -*-
require File.join(File.dirname(__FILE__), 'test_helper')

MIGRATIONS_ROOT = File.join(File.dirname(__FILE__), 'migrations')

class I18nExportTest < Test::Unit::TestCase

  ActiveRecord::Base.reset_subclasses

  class Product < ActiveRecord::Base; end

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
    
    assert_equal true, ActiveRecord::Base.export_i18n_models.keys.include?('i18n_export_test/product')
    assert_equal '商品', ActiveRecord::Base.export_i18n_models['i18n_export_test/product']
    
    assert_equal true, ActiveRecord::Base.export_i18n_attributes.keys.include?('i18n_export_test/product')
    assert_equal({
          'product_type_cd' => '種別コード', 
          "price" => "価格",
          "name" => "商品名",
          "created_at" => "登録日時",
          "updated_at" => "更新日時"
        }, ActiveRecord::Base.export_i18n_attributes['i18n_export_test/product'])
  end
  
end
