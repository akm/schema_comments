# -*- coding: utf-8 -*-
class ChangeComments < ActiveRecord::Migration[5.0]
  def self.up
    column_comments(:products, {:name => "商品名称"})
    column_comments("products", "product_type_cd" => 'カテゴリコード')
  end

  def self.down
    column_comments(:products, {:name => "名称"})
    column_comments("products", "product_type_cd" => '種別コード')
  end
end
