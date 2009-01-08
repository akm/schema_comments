# -*- coding: utf-8 -*-
module SchemaComments
  class SchemaComment < ActiveRecord::Base
    set_table_name('schema_comments')
    
    class << self
      def table_comment(table_name)
        return nil unless table_exists?
        connection.select_value(sanitize_conditions("select descriptions from schema_comments where table_name = '%s' and column_name is null" % table_name))
      end
      
      def column_comment(table_name, column_name)
        return nil unless table_exists?
        connection.select_value(sanitize_conditions("select descriptions from schema_comments where table_name = '%s' and column_name = '%s'" % [table_name, column_name]))
      end
      
      def column_comments(table_name)
        return {} unless table_exists?
        hash_array = connection.select_all(sanitize_conditions("select column_name, descriptions from schema_comments where table_name = '%s' and column_name is not null" % table_name))
        hash_array.inject({}){|dest, r| dest[r['column_name']] = r['descriptions']; dest}
      end
      
      def save_table_comment(table_name, comment)
        create_table unless table_exists?
        r = self.find(:first, :conditions => {:table_name => table_name}) || 
          self.new(:table_name => table_name)
        r.descriptions = comment
        r.save!
      end
      
      def save_column_comment(table_name, column_name, comment)
        create_table unless table_exists?
        r = self.find(:first, :conditions => {:table_name => table_name, :column_name => column_name}) || 
          self.new(:table_name => table_name, :column_name => column_name)
        r.descriptions = comment
        r.save!
      end
      
      def delete_by_table(table_name)
        return unless table_exists?
        self.destroy_all(:table_name => table_name)
      end
      
      def update_table_name(table_name, new_name)
        update_all(["table_name = ?", new_name], ["table_name = ?", table_name])
      end
      
      
      def create_table
        connection.create_table "schema_comments" do |t|
          t.string "table_name", :null => false
          t.string "column_name", :null => true
          t.string "descriptions", :null => true
        end
      end
      
    end
  end
end
