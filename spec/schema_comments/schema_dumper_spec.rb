# -*- coding: utf-8 -*-
require File.join(File.dirname(__FILE__), '../spec_helper')

describe ActiveRecord::SchemaDumper do

  before(:each) do
    SchemaComments.yaml_path = File.expand_path(File.join(File.dirname(__FILE__), 'schema_comments.yml'))
    FileUtils.rm(SchemaComments.yaml_path, :verbose => true) if File.exist?(SchemaComments.yaml_path)

    (ActiveRecord::Base.connection.tables - IGNORED_TABLES).each do |t|
      ActiveRecord::Base.connection.drop_table(t) rescue nil
    end
    ActiveRecord::Base.connection.initialize_schema_migrations_table
    ActiveRecord::Base.connection.execute "DELETE FROM #{ActiveRecord::Migrator.schema_migrations_table_name}"
  end

  describe :dump do
    it "products" do
      expect(ActiveRecord::Base.connection.tables - %w(schema_migrations)).to eq []

      migration_path = File.join(MIGRATIONS_ROOT, 'valid')
      Dir.glob('*.rb').each{|file| require(file) if /^\d+?_.*/ =~ file}

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

      dest = StringIO.new
      # ActiveRecord::SchemaDumper.dump(ActiveRecord::Base.connection, dest)
      SchemaComments::SchemaDumper.dump(ActiveRecord::Base.connection, dest)
      dest.rewind
      s = <<EOS
# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 1) do

  create_table "products", :force => true, :comment => '商品' do |t|
EOS

      if ENV['DB'] =~ /mysql/i
        s << <<EOS
    #t.column "id",              "int(11)",                     :null => false, :comment => "AUTO_INCREMENT PRIMARY KEY by rails"
    t.column "product_type_cd", "varchar(255)",                                :comment => "種別コード"
    t.column "price",           "int(11)",      :default => 0,                 :comment => "価格"
    t.column "name",            "varchar(255)",                                :comment => "商品名"
    t.column "created_at",      "datetime",                                    :comment => "登録日時"
    t.column "updated_at",      "datetime",                                    :comment => "更新日時"
EOS
      else
        s << <<EOS
    t.string   "product_type_cd",                :comment => "種別コード"
    t.integer  "price",           :default => 0, :comment => "価格"
    t.string   "name",                           :comment => "商品名"
    t.datetime "created_at",                     :comment => "登録日時"
    t.datetime "updated_at",                     :comment => "更新日時"
EOS
      end
      s << <<EOS
  end

end
EOS
      expect(dest.read).to eq s
    end

  end
end
