# -*- coding: utf-8 -*-
class ChangeProductsName < ActiveRecord::Migration
  def self.up
    change_column "products", 'name', :string, :limit => 50
  end

  def self.down
    change_column "products", 'name', :string
  end
end
