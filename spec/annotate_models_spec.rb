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
    
    ActiveRecord::Schema.define(:version => nil) do
      drop_table("books") rescue nil

      create_table "books", :force => true do |t|
        t.string   "title", :limit => 100, :null => false
        t.integer  "size", :null => false, :default => 1
        t.decimal  "price", :precision => 17, :scale => 14, :default => 0.0, :null => false
        t.datetime "created_at"
        t.datetime "updated_at"
      end
    end

    class Book < ActiveRecord::Base
    end


    AnnotateModels.get_schema_info(Book, 'HEADER1').should == %{# HEADER1
#
# Table name: books
#
#  id         :integer         not null, primary key
#  name       :string(100)     not null
#  price      :decimal(17, 14) not null, default(0.0)
#  size       :integer         not null, default(1)
#  created_at :datetime
#  updated_at :datetime}
  end
  
  
end
