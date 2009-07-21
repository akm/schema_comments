
# fork from
# http://github.com/rotuka/annotate_models/blob/d2afee82020dbc592b147d92f9beeadbf665a9e0/lib/annotate_models.rb

require "config/environment" if File.exist?("config/environment")

MODEL_DIR         = File.join(RAILS_ROOT, "app/models" )
UNIT_TEST_DIR     = File.join(RAILS_ROOT, "test/unit"  )
SPEC_MODEL_DIR    = File.join(RAILS_ROOT, "spec/models")
FIXTURES_DIR      = File.join(RAILS_ROOT, "test/fixtures")
SPEC_FIXTURES_DIR = File.join(RAILS_ROOT, "spec/fixtures")

module AnnotateModels
  
  PREFIX_AT_BOTTOM = "== Schema Info"
  SUFFIX_AT_BOTTOM = ""
  PREFIX_ON_TOP = "== Schema Info =="
  SUFFIX_ON_TOP = "=================\n# "

  # ENV options
  {:position => 'top', :model_dir => MODEL_DIR}.each do |name, default_value|
    mattr_accessor name.to_sym
    self.send("#{name}=", ENV[name.to_s.upcase] || default_value)
  end

  def self.models
    (ENV['MODELS'] || '').split(',')
  end

  def self.sort_columns
    ENV['SORT'] =~ /yes|on|true/i
  end

  def self.output_prefix
    bottom? ? PREFIX_AT_BOTTOM : PREFIX_ON_TOP
  end

  def self.output_suffix
    bottom? ? SUFFIX_AT_BOTTOM : SUFFIX_ON_TOP
  end

  def self.bottom?
    self.position =~ /bottom/i
  end

  def self.separate?
    ENV['SEPARATE'] =~ /yes|on|true/i
  end


  # Simple quoting for the default column value
  def self.quote(value)
    case value
    when NilClass                 then "NULL"
    when TrueClass                then "TRUE"
    when FalseClass               then "FALSE"
    when Float, Fixnum, Bignum    then value.to_s
      # BigDecimals need to be output in a non-normalized form and quoted.
    when BigDecimal               then value.to_s('F')
    else
      value.inspect
    end
  end
  
  # Use the column information in an ActiveRecord class
  # to create a comment block containing a line for
  # each column. The line contains the column name,
  # the type (and length), and any optional attributes
  def self.get_schema_info(klass)
    table_info = "# Table name: #{klass.table_name}"
    table_info << " # #{klass.table_comment}" unless klass.table_comment.blank?
    table_info << "\n#\n"
    max_size = klass.column_names.collect{|name| name.size}.max + 1
    
    columns = klass.columns

    cols = if self.sort_columns
             pk    = columns.find_all { |col| col.name == klass.primary_key }.flatten
             assoc = columns.find_all { |col| col.name.match(/_id$/) }.sort_by(&:name)
             dates = columns.find_all { |col| col.name.match(/_on$/) }.sort_by(&:name)
             times = columns.find_all { |col| col.name.match(/_at$/) }.sort_by(&:name)
             pk + assoc + (columns - pk - assoc - times - dates).compact.sort_by(&:name) + dates + times
           else
             columns
           end
    
    col_lines = append_comments(cols.map{|col| [col, annotate_column(col, klass, max_size)]})
    cols_text = col_lines.join("\n")
    
    result = "# #{self.output_prefix}\n# \n# Schema version: #{get_schema_version}\n#\n"
    result << table_info
    result << cols_text
    result << "\n# \n# #{self.output_suffix}" unless self.output_suffix.blank?
    result << "\n"
    result
  end
  
  def self.annotate_column(col, klass, max_size)
    attrs = []
    attrs << "not null" unless col.null
    attrs << "default(#{quote(col.default)})" if col.default
    attrs << "primary key" if col.name == klass.primary_key
    
    col_type = col.type.to_s
    if col_type == "decimal"
      col_type << "(#{col.precision}, #{col.scale})"
    else
      col_type << "(#{col.limit})" if col.limit
    end
    sprintf("#  %-#{max_size}s:%-15s %s", col.name, col_type, attrs.join(", ")).rstrip
  end

  def self.append_comments(col_and_lines)
    max_length = col_and_lines.map{|(col, line)| line.length}.max
    col_and_lines.map do |(col, line)|
      if col.comment.blank?
        line
      else
        "%-#{max_length}s # %s" % [line, col.comment]
      end
    end
  end
  
  # Add a schema block to a file. If the file already contains
  # a schema info block (a comment starting
  # with "Schema as of ..."), remove it first.
  # Mod to write to the end of the file
  def self.annotate_one_file(file_name, info_block)
    if File.exist?(file_name)
      content = File.read(file_name)
      
      encoding_comment = content.scan(/^\#\s*-\*-(.+?)-\*-/).flatten.first
      content.sub!(/^\#\s*-\*-(.+?)-\*-/, '')

      # Remove old schema info
      content.sub!(/(\n)*^# #{PREFIX_ON_TOP}.*?\n(#.*\n)*# #{SUFFIX_ON_TOP}/, '')
      content.sub!(/(\n)*^# #{PREFIX_AT_BOTTOM}.*?\n(#.*\n)*#.*(\n)*/, '')
      content.sub!(/^[\n\s]*/, '')
      
      # Write it back
      File.open(file_name, "w") do |f|
        f.print "# -*- #{encoding_comment.strip} -*-\n\n" unless encoding_comment.blank?
        if self.bottom?
          f.print content
          f.print "\n\n"
          f.print info_block
        else
          f.print info_block
          f.print "\n" if self.separate?
          f.print content
        end
      end
    end
  end

  
  # Given the name of an ActiveRecord class, create a schema
  # info block (basically a comment containing information
  # on the columns and their types) and put it at the front
  # of the model and fixture source files.  
  def self.annotate(klass)
    info = get_schema_info(klass)
    model_name = klass.name.underscore
    fixtures_name = "#{klass.table_name}.yml"
    
    [
      File.join(self.model_dir,     "#{model_name}.rb"),      # model
      File.join(UNIT_TEST_DIR,      "#{model_name}_test.rb"), # test
      File.join(FIXTURES_DIR,       fixtures_name),           # fixture
      File.join(SPEC_MODEL_DIR,     "#{model_name}_spec.rb"), # spec
      File.join(SPEC_FIXTURES_DIR,  fixtures_name),           # spec fixture
      File.join(RAILS_ROOT,         'test', 'factories.rb'),  # factories file
      File.join(RAILS_ROOT,         'spec', 'factories.rb'),  # factories file
    ].each { |file| annotate_one_file(file, info) }
  end
  
  # Return a list of the model files to annotate. If we have
  # command line arguments, they're assumed to be either
  # the underscore or CamelCase versions of model names.
  # Otherwise we take all the model files in the
  # app/models directory.
  def self.get_model_names
    result = nil
    if self.models.empty?
      Dir.chdir(self.model_dir) do
        result = Dir["**/*.rb"].map do |filename| 
          filename.sub(/\.rb$/, '').camelize
        end
      end
    else
      result = self.models.dup
    end
    result 
  end
  
  # We're passed a name of things that might be
  # ActiveRecord models. If we can find the class, and
  # if its a subclass of ActiveRecord::Base,
  # then pas it to the associated block
  def self.do_annotations
    annotated = self.get_model_names.inject([]) do |list, class_name|
      begin
        # klass = class_name.split('::').inject(Object){ |klass,part| klass.const_get(part) }
        klass = class_name.constantize
        if klass < ActiveRecord::Base && !klass.abstract_class?
          list << class_name
          self.annotate(klass)
        end
      rescue Exception => e
        puts "Unable to annotate #{class_name}: #{e.message}"
      end
      list
    end
    puts "Annotated #{annotated.join(', ')}"
  end
  
  def self.get_schema_version
    unless @schema_version
      version = ActiveRecord::Migrator.current_version rescue 0
      @schema_version = version > 0 ? version : ''
    end
    @schema_version
  end
end
