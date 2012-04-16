# -*- coding: utf-8 -*-
require File.join(File.dirname(__FILE__), 'spec_helper')

require File.join(File.dirname(__FILE__), '../lib/annotate_models.rb')

describe AnnotateModels do

  before(:each) do
    SchemaComments.yaml_path = File.expand_path(File.join(File.dirname(__FILE__), 'schema_comments.yml'))
    FileUtils.rm(SchemaComments.yaml_path, :verbose => true) if File.exist?(SchemaComments.yaml_path)

    (ActiveRecord::Base.connection.tables - IGNORED_TABLES).each do |t|
      ActiveRecord::Base.connection.drop_table(t) rescue nil
    end
    ActiveRecord::Base.connection.initialize_schema_migrations_table
    ActiveRecord::Base.connection.execute "DELETE FROM #{ActiveRecord::Migrator.schema_migrations_table_name}"
  end

  it "get_schema_info" do
    (ActiveRecord::Base.connection.tables - %w(schema_migrations)).should == []

    ActiveRecord::Schema.define(:version => "20090721185959") do
      drop_table("books") rescue nil

      create_table "books", :force => true, :comment => '書籍' do |t|
        t.string   "title", :limit => 100, :null => false, :comment => 'タイトル'
        t.integer  "size", :null => false, :default => 1, :comment => '判型'
        t.decimal  "price", :precision => 17, :scale => 14, :default => 0.0, :null => false, :comment => '価格'
        t.datetime "created_at", :comment => '登録日時'
        t.datetime "updated_at", :comment => '更新日時'
      end
    end

    class Book < ActiveRecord::Base
    end


    AnnotateModels.get_schema_info(Book).should == %{# == Schema Info ==
#
# Schema version: 20090721185959
#
# Table name: books # 書籍
#
#  id         :integer         not null, primary key
#  title      :string(100)     not null               # タイトル
#  size       :integer         not null, default(1)   # 判型
#  price      :decimal(17, 14) not null, default(0.0) # 価格
#  created_at :datetime                               # 登録日時
#  updated_at :datetime                               # 更新日時
#
# =================
#
}
  end

end
