# -*- coding: utf-8 -*-
class RemovePrice < ActiveRecord::Migration
  def self.up
    remove_column "products", "price"
  end

  def self.down
    add_column "products", "price", :integer, :comment => "価格"
  end
end
