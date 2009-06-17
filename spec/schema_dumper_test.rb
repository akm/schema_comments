# -*- coding: utf-8 -*-
require File.join(File.dirname(__FILE__), 'test_helper')

class SchemaDumperTest < Test::Unit::TestCase

  IGNORED_TABLES = %w(schema_migrations)
  

  def setup
    (ActiveRecord::Base.connection.tables - IGNORED_TABLES).each do |t|
      ActiveRecord::Base.connection.drop_table(t) rescue nil
    end
    ActiveRecord::Base.connection.initialize_schema_migrations_table
    ActiveRecord::Base.connection.execute "DELETE FROM #{ActiveRecord::Migrator.schema_migrations_table_name}"
  end
  
  def test_dump
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

    dest = StringIO.new
    ActiveRecord::SchemaDumper.dump(ActiveRecord::Base.connection, dest)
    dest.rewind
    assert_equal(<<EOS, dest.read)
# This file is auto-generated from the current state of the database. Instead of editing this file, 
# please use the migrations feature of Active Record to incrementally modify your database, and
# then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your database schema. If you need
# to create the application database on another system, you should be using db:schema:load, not running
# all the migrations from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 1) do

  create_table "products", :force => true, :comment => '商品' do |t|
    t.string   "product_type_cd", :comment => "種別コード"
    t.integer  "price",           :comment => "価格"
    t.string   "name",            :comment => "商品名"
    t.datetime "created_at",      :comment => "登録日時"
    t.datetime "updated_at",      :comment => "更新日時"
  end

end
EOS
  end
  
end
