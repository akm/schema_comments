# -*- coding: utf-8 -*-
class CreateProducts < ActiveRecord::Migration

  def self.up
    create_table "products", :comment => '商品' do |t|
      t.string   "product_type_cd", :comment => '種別コード'
      t.integer  "price", :comment => "価格", default: 0
      t.string   "name", :comment => "商品名"
      t.datetime "created_at", :comment => "登録日時"
      t.datetime "updated_at", :comment => "更新日時"
    end
  end

  def self.down
    drop_table "products"
  end
end
