# -*- coding: utf-8 -*-
class ChangeProductsNameWithComment < ActiveRecord::Migration[5.0]
  def self.up
    change_column "products", 'name', :string, :limit => 100, :comment => "名称"
  end

  def self.down
    change_column "products", 'name', :string, :limit => 50, :comment => "商品名"
  end
end
