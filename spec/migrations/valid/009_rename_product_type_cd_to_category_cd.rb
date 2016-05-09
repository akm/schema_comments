# -*- coding: utf-8 -*-
class RenameProductTypeCdToCategoryCd < ActiveRecord::Migration
  def self.up
    rename_column :products, :product_type_cd, :category_cd, comment: 'カテゴリーコード'
  end

  def self.down
    rename_column :products, :category_cd, :product_type_cd, comment: 'カテゴリコード'
  end
end
