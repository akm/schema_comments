# -*- coding: utf-8 -*-
module SchemaComments
  module SchemaDumper
    def self.included(mod)
#       mod.extend(ClassMethods)
#       mod.instance_eval do 
#         alias :ignore_tables_without_schema_comments :ignore_tables
#         alias :ignore_tables :ignore_tables_with_schema_comments 
#       end
      mod.module_eval do 
        alias_method_chain :tables, :schema_comments
        alias_method_chain :table, :schema_comments
      end
    end
    
    IGNORED_TABLE = 'schema_comments'
    
#     module ClassMethods
#       def ignore_tables_with_schema_comments
#         result = ignore_tables_without_schema_comments
#         result << IGNORED_TABLE unless result.include?(IGNORED_TABLE)
#         result
#       end
#     end
    
    private
    def tables_with_schema_comments(stream)
      tables_without_schema_comments(stream)
      if adapter_name == "mysql"
        # ビューはtableの後に実行するようにしないと rake db:schema:load で失敗します。
        mysql_views(stream)
      end
    end

    def table_with_schema_comments(table, stream)
      return if IGNORED_TABLE == table.downcase
      # MySQLは、ビューもテーブルとして扱うので、一個一個チェックします。
      if adapter_name == 'mysql'
        config = ActiveRecord::Base.configurations[RAILS_ENV]
        match_count = @connection.select_value(
          "select count(*) from information_schema.TABLES where TABLE_TYPE = 'VIEW' AND TABLE_SCHEMA = '%s' AND TABLE_NAME = '%s'" % [
            config["database"], table])
        return if match_count.to_i > 0
      end
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
          spec[:comment]   = '"' << (column.comment || '').gsub(/\"/, '\"') << '"' # ここでinspectを使うと最後の文字だけ文字化け(UTF-8のコード)になっちゃう
          (spec.keys - [:name, :type]).each{ |k| spec[k].insert(0, "#{k.inspect} => ")}
          spec
        end.compact

        # find all migration keys used in this table
        keys = [:name, :limit, :precision, :scale, :default, :null, :comment] & column_specs.map(&:keys).flatten

        # figure out the lengths for each column based on above keys
        lengths = keys.map{ |key|
          column_specs.map{ |spec| spec[key] ? spec[key].length + 2 : 0 }.max
        }

        # the string we're going to sprintf our values against, with standardized column widths
        format_string = lengths.map{|len| len ? "%-#{len}s" : "%s" }

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

    def adapter_name
      config = ActiveRecord::Base.configurations[RAILS_ENV]
      config ? config['adapter'] : ActiveRecord::Base.connection.adapter_name
    end

    def mysql_views(stream)
      config = ActiveRecord::Base.configurations[RAILS_ENV]
      view_names = @connection.select_values(
        "select TABLE_NAME from information_schema.TABLES where TABLE_TYPE = 'VIEW' AND TABLE_SCHEMA = '%s'" % config["database"])
      view_names.each do |view_name|
        mysql_view(view_name, stream)
      end
    end
    
    def mysql_view(view_name, stream)
      ddl = @connection.select_value("show create view #{view_name}")
      ddl.gsub!(/^CREATE .+? VIEW /i, "CREATE OR REPLACE VIEW ")
      ddl.gsub!(/AS select/, "AS \n select\n")
      ddl.gsub!(/( AS \`.+?\`\,)/){ "#{$1}\n" }
      ddl.gsub!(/ from /i         , "\n from \n")
      ddl.gsub!(/ where /i        , "\n where \n")
      ddl.gsub!(/ order by /i     , "\n order by \n")
      ddl.gsub!(/ having /i       , "\n having \n")
      ddl.gsub!(/ union /i        , "\n union \n")
      ddl.gsub!(/ and /i          , "\n and ")
      ddl.gsub!(/ or /i           , "\n or ")
      ddl.gsub!(/inner join/i     , "\n inner join")
      ddl.gsub!(/left join/i      , "\n left join")
      ddl.gsub!(/left outer join/i, "\n left outer join")
      stream.print("  ActiveRecord::Base.connection.execute(<<-EOS)\n")
      stream.print(ddl.split(/\n/).map{|line| '    ' << line.strip}.join("\n"))
      stream.print("\n  EOS\n")
    end
    
  end
end
