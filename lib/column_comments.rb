class ActiveRecord::Base
  class << self
    def table_comment
      @table_comment = connection.table_comment(table_name) unless @table_comment
      @table_comment
    end
  end
end

module ActiveRecord::ConnectionAdapters
  # Add a @comment attribute to columns
  class Column
    attr_reader :comment
    def initialize_with_column_comments(name, default, sql_type = nil, null = true, comment = nil)
      initialize_without_column_comments(name, default, sql_type, null)
      @comment = comment
    end
    alias_method_chain :initialize, :column_comments
  end
  
  # Sneak the comment in through the add_column_options! method when create_table is called with a block
  class ColumnDefinition < ColumnDefinition.superclass #:nodoc:
    attr_accessor :comment
    
    private
    
    def add_column_options_with_column_comments!(sql, options)
      add_column_options_without_column_comments!(sql, options.merge(:comment => comment))
    end
    alias_method_chain :add_column_options!, :column_comments
  end
  
  # Pass the comment through the TableDefinition
  class TableDefinition
    attr_accessor :comment

    def column_with_column_comments(name, type, options = {})
      column_without_column_comments(name, type, options)
      column = self[name]
      column.comment = options[:comment]
      self
    end
    alias_method_chain :column, :column_comments
  end
  
  # Get comments on each when querying for column structure
  class MysqlAdapter < AbstractAdapter
    def columns(table_name, name = nil)#:nodoc:
      sql = "SHOW FULL FIELDS FROM #{table_name}"
      columns = []
      execute(sql, name).each { |field| columns << MysqlColumn.new(field[0], field[5], field[1], field[3] == "YES", field[8]) }
      columns
    end
    
    # See also TableDefinition#column for details on how to create columns.
    def create_table(table_name, options = {})
      super
      table_comment(table_name, options[:comment]) unless options[:comment].blank?
    end

    # Add an optional :comment to the options passed to change_column
    def add_column_options_with_column_comments!(sql, options) #:nodoc:
      add_column_options_without_column_comments!(sql, options)
      sql << " COMMENT #{quote(options[:comment])}" if options[:comment]
      #STDERR << "Column with options: #{sql}\n"
      sql
    end
    alias_method_chain :add_column_options!, :column_comments
    
    # Make sure we don't lose the comment when changing the name
    def rename_column(table_name, column_name, new_column_name, options = {}) #:nodoc:
      column_info = select_one("SHOW FULL FIELDS FROM #{table_name} LIKE '#{column_name}'")
      current_type = column_info["Type"]
      options[:comment] ||= column_info["Comment"]
      sql = "ALTER TABLE #{table_name} CHANGE #{column_name} #{new_column_name} #{current_type}"
      sql << " COMMENT #{quote(options[:comment])}" unless options[:comment].blank?
      execute sql
    end
    
    # Allow column comments to be explicitly set
    def column_comment(table_name, column_name, comment) #:nodoc:
      rename_column(table_name, column_name, column_name, :comment => comment)
    end
    
    # Mass assignment of comments in the form of a hash.  Example:
    #   column_comments {
    #     :users => {:first_name => "User's given name", :last_name => "Family name"},
    #     :tags  => {:id => "Tag IDentifier"}}
    def column_comments(contents)
      contents.each_pair do |table, cols|
        cols.each_pair do |col, comment|
          column_comment(table, col, comment)
        end
      end
    end
    
    def table_comment(table_name, comment = nil) #:nodoc:
      if comment
        sql = "alter table %s comment '%s'" % [table_name, comment]
        execute sql
        return comment
      else
        sql = "show table status like '%s'" % table_name
        record = select_one(sql)
        table_comment = record['Comment']
        return table_comment.nil? ? nil : table_comment.split(';', 2).first
      end
    end
    
  end
end

module ActiveRecord
  class Migration
    class CommentBuilder
      def initialize(migration, table)
        @migration, @table = migration, table
      end
      
      def comment(column, str)
        @migration.column_comment(@table, column, str)
      end
    end
    
    def self.table_comment(table_name, comment, &block)
      comment = (comment[:comment] || comment['comment']) if comment.is_a?(Hash)
      ActiveRecord::Base.connection.table_comment(table_name, comment)
      if block_given?
        builder = CommentBuilder.new(self, table_name)
        yield(builder)
      end
    end

    def self.column_comment(table, column, comment)
      column_comments(table => {column => comment})
    end

    def self.table_comments(table_comments)
      table_comments.each do |table_name, comment|
        table_comment(table_name, comment)
      end
    end

    def self.column_comments(*args)
      ActiveRecord::Base.connection.column_comments(*args)
    end
  end
  
  class SchemaDumper
    private
    def table(table, stream)
      columns = @connection.columns(table)
      begin
        tbl = StringIO.new

        if @connection.respond_to?(:pk_and_sequence_for)
          pk, pk_seq = @connection.pk_and_sequence_for(table)
        end
        pk ||= 'id'

        tbl.print "  create_table #{table.inspect}"
        if columns.detect { |c| c.name == pk }
          if pk != 'id'
            tbl.print %Q(, :primary_key => "#{pk}")
          end
        else
          tbl.print ", :id => false"
        end
        tbl.print ", :force => true"
        
        table_comment = @connection.table_comment(table)
        tbl.print ", :comment => '#{table_comment}'" unless table_comment.blank?
        
        tbl.puts " do |t|"

        column_specs = columns.map do |column|
          raise StandardError, "Unknown type '#{column.sql_type}' for column '#{column.name}'" if @types[column.type].nil?
          next if column.name == pk
          spec = {}
          spec[:name]      = column.name.inspect
          spec[:type]      = column.type.to_s
          spec[:limit]     = column.limit.inspect if column.limit != @types[column.type][:limit] && column.type != :decimal
          spec[:precision] = column.precision.inspect if !column.precision.nil?
          spec[:scale]     = column.scale.inspect if !column.scale.nil?
          spec[:null]      = 'false' if !column.null
          spec[:default]   = default_string(column.default) if !column.default.nil?
          spec[:comment]   = column.comment.inspect unless column.comment.nil?
          (spec.keys - [:name, :type]).each{ |k| spec[k].insert(0, "#{k.inspect} => ")}
          spec
        end.compact

        # find all migration keys used in this table
        keys = [:name, :limit, :precision, :scale, :default, :null, :comment] & column_specs.map(&:keys).flatten

        # figure out the lengths for each column based on above keys
        lengths = keys.map{ |key| column_specs.map{ |spec| spec[key] ? spec[key].length + 2 : 0 }.max }

        # the string we're going to sprintf our values against, with standardized column widths
        format_string = lengths.map{ |len| "%-#{len}s" }

        # find the max length for the 'type' column, which is special
        type_length = column_specs.map{ |column| column[:type].length }.max

        # add column type definition to our format string
        format_string.unshift "    t.%-#{type_length}s "

        format_string *= ''

        column_specs.each do |colspec|
          values = keys.zip(lengths).map{ |key, len| colspec.key?(key) ? colspec[key] + ", " : " " * len }
          values.unshift colspec[:type]
          tbl.print((format_string % values).gsub(/,\s*$/, ''))
          tbl.puts
        end

        tbl.puts "  end"
        tbl.puts
        
        indexes(table, tbl)

        tbl.rewind
        stream.print tbl.read
      rescue => e
        stream.puts "# Could not dump table #{table.inspect} because of following #{e.class}"
        stream.puts "#   #{e.message}"
        stream.puts
      end
      
      stream
    end
  end
end
