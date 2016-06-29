# -*- coding: utf-8 -*-
class CreateUsersWithoutComment < ActiveRecord::Migration
  def self.up
    create_table :users do |t|
      t.string :login
      t.string :email
      t.string :crypted_password
      t.string :password_salt
      t.string :persistence_token
      t.string :single_access_token
      t.string :perishable_token
      t.timestamps null: false
    end
  end

  def self.down
    drop_table :users
  end
end
