# -*- coding: utf-8 -*-
module SchemaComments
  class SchemaDumper < ActiveRecord::SchemaDumper
    include ActiveRecord::ConnectionAdapters::ColumnDumper # for schema_default

    autoload :Mysql, 'schema_comments/schema_dumper/mysql'

    def self.dump(connection=ActiveRecord::Base.connection, stream=STDOUT)
      dumper =
        case connection.adapter_name
        when /mysql/i then
          SchemaComments::SchemaDumper::Mysql.new(connection)
        else
          new(connection)
        end
      dumper.dump(stream)
      stream
    end

    def dump(stream)
      header(stream)
      tables(stream)
      selectable_attrs(stream)
      trailer(stream)
      stream
    end

    private

    def table(table, stream)
      columns = @connection.columns(table)
      begin
        tbl = StringIO.new

        # first dump primary key column
        if @connection.respond_to?(:pk_and_sequence_for)
          pk, _ = @connection.pk_and_sequence_for(table)
        elsif @connection.respond_to?(:primary_key)
          pk = @connection.primary_key(table)
        end

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

        # then dump all non-primary key columns
        column_specs = columns.map do |column|
          raise StandardError, "Unknown type '#{column.sql_type}' for column '#{column.name}'" if @types[column.type].nil?
          next if column.name == pk
          spec = {}
          spec[:name]      = column.name.inspect

          # AR has an optimization which handles zero-scale decimals as integers. This
          # code ensures that the dumper still dumps the column as a decimal.
          spec[:type]      = if column.type == :integer && [/^numeric/, /^decimal/].any? { |e| e.match(column.sql_type) }
                               'decimal'
                             else
                               column.type.to_s
                             end
          spec[:limit]     = column.limit.inspect if column.limit != @types[column.type][:limit] && spec[:type] != 'decimal'
          spec[:precision] = column.precision.inspect if column.precision
          spec[:scale]     = column.scale.inspect if column.scale
          spec[:null]      = 'false' unless column.null
          default = schema_default(column) if column.has_default?
          spec[:default]   = schema_default(column) unless default.nil?
          spec[:comment]   = '"' << (column.comment || '').gsub(/\"/, '\"') << '"' # ここでinspectを使うと最後の文字だけ文字化け(UTF-8のコード)になっちゃう
          (spec.keys - [:name, :type]).each{ |k| spec[k].insert(0, "#{k.inspect} => ")}
          spec
        end.compact

        # find all migration keys used in this table
        keys = [:name, :limit, :precision, :scale, :default, :null, :comment] & column_specs.map{ |k| k.keys }.flatten

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

    def adapter_name
      config = ActiveRecord::Base.configurations[Rails.env]
      config ? config['adapter'] : ActiveRecord::Base.connection.adapter_name
    end

    def selectable_attrs(stream)
      return unless defined?(SelectableAttr)
      enum_defs = []
      classes = Dir["app/models/*.rb"].map{|f| File.basename(f, ".*").camelize.constantize}.select{|k| k.respond_to?(:single_selectable_attrs)}
      classes.each do |klass|
        (klass.single_selectable_attrs + klass.multi_selectable_attrs).each do |enum_name|
          enum = klass.send(klass.enum_base_name(enum_name) + "_enum")
          enum_def = enum_defs.detect{|enum_def| enum_def[:enum] === enum && enum_def[:enum_name] == enum_name}
          unless enum_def
            enum_def = {:enum => enum, :enum_name => enum_name, :usages => []}
            enum_defs << enum_def
          end
          enum_def[:usages] << {:class => klass, :enum_name => enum_name}
        end
      end

      stream.puts

      enum_defs.each do |enum_def|
        selectable_attr(enum_def[:enum], enum_def[:usages], stream)
      end
    end

    def selectable_attr(enum, usages, stream)
      buf = StringIO.new

      specs = []
      usages.each do |usage|
        klass = usage[:class]
        method_caption = nil
        if col = usage[:class].columns.detect{|c| c.name == usage[:enum_name]}
          method_caption = col.comment
        end
        method_caption ||= usage[:enum_name]
        spec = {
          :class_name => klass.name,
          :methos_name => usage[:enum_name],
          :class_caption => klass.table_comment,
          :method_caption => method_caption
        }
        specs << spec
      end
      keys = [:class_name, :methos_name, :class_caption, :method_caption]
      lengths = keys.map{ |key| specs.map{ |spec| spec[key] ? spec[key].length + 2 : 0 }.max }
      format_string = lengths.map{ |len| "%-#{len}s" }
      format_string *= ''
      specs.each do |spec|
        values = keys.zip(lengths).map{ |key, len| spec.key?(key) ? spec[key] + " " : " " * len }
        buf.print('  # ')
        buf.print((format_string % values).gsub(/,\s*$/, '').strip)
        buf.puts
      end
      buf.puts "  #"

      selectable_attr_with_default(enum, usages, buf)

      buf.puts "  #"
      buf.puts

      buf.rewind
      stream.print buf.read
    end

    def selectable_attr_with_default(enum, usages, buf)
      entry_specs = enum.entries.map do |e|
        {:id => "#{e.id.inspect} |", :name => e.name.inspect, :options => e.options ? e.options.inspect : ''}
      end
      entry_specs.unshift({
          :id => "val |", :name => "name and options", :options => ""})
      keys = [:id, :name, :options] & entry_specs.map{ |k| k.keys }.flatten
      lengths = keys.map{ |key| entry_specs.map{ |spec| spec[key] ? spec[key].length + 2 : 0 }.max }
      format_string = ["%#{lengths[0]}s" ] + lengths[1..-1].map{ |len| "%-#{len}s" }
      format_string *= ''
      entry_specs.each_with_index do |enum_spec, idx|
        values = keys.zip(lengths).map{ |key, len| enum_spec.key?(key) ? enum_spec[key] + " " : " " * len }
        line = (format_string % values).gsub(/\s+\Z/, '')
        buf.print('  # ')
        buf.print(line)
        buf.puts
        if idx == 0
          buf.print('  # ')
          buf.puts("-" * line.length)
        end
      end
    end

  end
end
