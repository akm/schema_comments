# -*- coding: utf-8 -*-
class RenameProducts < ActiveRecord::Migration[5.0]
  def self.up
    rename_table "products", "product_names"
  end

  def self.down
    rename_table "product_names", "products"
  end
end
