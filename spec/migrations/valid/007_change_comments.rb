# -*- coding: utf-8 -*-
class ChangeComments < ActiveRecord::Migration
  def self.up
    column_comments(:products, :name => "商品名称")
  end

  def self.down
    column_comments(:products, :name => "名称")
  end
end
