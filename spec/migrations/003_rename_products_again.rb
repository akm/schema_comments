# -*- coding: utf-8 -*-
class RenameProductsAgain < ActiveRecord::Migration[5.0]
  def self.up
    rename_table "product_names", "products"
  end

  def self.down
    rename_table "products", "product_names"
  end
end
