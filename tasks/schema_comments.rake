# -*- coding: utf-8 -*-
require 'yaml'
require 'yaml_waml'
require 'active_record'

# テストを実行する際はschema_commentsのschema_comments.ymlへの出力を抑制します。
namespace :db do
  Rake.application.send(:eval, "@tasks.delete('db:migrate')")
  desc "Migrate the database through scripts in db/migrate and update db/schema.rb by invoking db:schema:dump. Target specific version with VERSION=x. Turn off output with VERBOSE=false."
  task :migrate => :environment do
    SchemaComments::SchemaComment.yaml_access do
      ActiveRecord::Migration.verbose = ENV["VERBOSE"] ? ENV["VERBOSE"] == "true" : true
      ActiveRecord::Migrator.migrate("db/migrate/", ENV["VERSION"] ? ENV["VERSION"].to_i : nil)
      SchemaComments.quiet = true
      Rake::Task["db:schema:dump"].invoke if ActiveRecord::Base.schema_format == :ruby
    end
  end

  Rake.application.send(:eval, "@tasks.delete('db:rollback')")
  desc 'Rolls the schema back to the previous version. Specify the number of steps with STEP=n'
  task :rollback => :environment do
    SchemaComments::SchemaComment.yaml_access do
      step = ENV['STEP'] ? ENV['STEP'].to_i : 1
      ActiveRecord::Migrator.rollback('db/migrate/', step)
      SchemaComments.quiet = true
      Rake::Task["db:schema:dump"].invoke if ActiveRecord::Base.schema_format == :ruby
    end
  end

  namespace :migrate do
    desc 'Runs the "up" for a given migration VERSION.'
    task :up => :environment do
      SchemaComments::SchemaComment.yaml_access do
        version = ENV["VERSION"] ? ENV["VERSION"].to_i : nil
        raise "VERSION is required" unless version
        ActiveRecord::Migrator.run(:up, "db/migrate/", version)
        SchemaComments.quiet = true
        Rake::Task["db:schema:dump"].invoke if ActiveRecord::Base.schema_format == :ruby
      end
    end

    desc 'Runs the "down" for a given migration VERSION.'
    task :down => :environment do
      SchemaComments::SchemaComment.yaml_access do
        version = ENV["VERSION"] ? ENV["VERSION"].to_i : nil
        raise "VERSION is required" unless version
        ActiveRecord::Migrator.run(:down, "db/migrate/", version)
        SchemaComments.quiet = true
        Rake::Task["db:schema:dump"].invoke if ActiveRecord::Base.schema_format == :ruby
      end
    end
  end

  namespace :test do
    Rake.application.send(:eval, "@tasks.delete('db:test:prepare')")
    desc 'Check for pending migrations and load the test schema'
    task :prepare => 'db:abort_if_pending_migrations' do
      SchemaComments::SchemaComment.yaml_access do
        SchemaComments.quiet = true
        if defined?(ActiveRecord) && !ActiveRecord::Base.configurations.blank?
          Rake::Task[{ :sql  => "db:test:clone_structure", :ruby => "db:test:load"
          }[ActiveRecord::Base.schema_format]].invoke
        end
      end
    end
  end

end



class ActiveRecord::Base
  class << self
    attr_accessor :ignore_pattern_to_export_i18n
  end

  self.ignore_pattern_to_export_i18n = /\(\(\(.*\)\)\)/

  class << self
    def export_i18n_models
      subclasses = ActiveRecord::Base.send(:subclasses).select do |klass|
        (klass != SchemaComments::SchemaComment) and
          klass.respond_to?(:table_exists?) and klass.table_exists?
      end
      result = subclasses.inject({}) do |d, m|
        comment = (m.table_comment || '').dup
        comment.gsub!(ignore_pattern_to_export_i18n, '') if ignore_pattern_to_export_i18n
        # テーブル名(複数形)をモデル名(単数形)に
        model_name = (comment.scan(/\[\[\[(?:model|class)(?:_name)?:\s*?([^\s]+?)\s*?\]\]\]/).flatten.first || m.name).underscore
        comment.gsub!(/\[\[\[.*?\]\]\]/)
        d[model_name] = comment
        d
      end
      result.instance_eval do
        def each_with_order(*args, &block)
          self.keys.sort.each do |key|
            yield(key, self[key])
          end
        end
        alias :each_without_order :each
        alias :each :each_with_order
      end
      result
    end

    def export_i18n_attributes
      subclasses = ActiveRecord::Base.send(:subclasses).select do |klass|
        (klass != SchemaComments::SchemaComment) and
          klass.respond_to?(:table_exists?) and klass.table_exists?
      end
      result = subclasses.inject({}) do |d, m|
        attrs = {}
        m.columns.each do |col|
          next if col.name == 'id'
          comment = (col.comment || '').dup
          comment.gsub!(ignore_pattern_to_export_i18n, '') if ignore_pattern_to_export_i18n

          # カラム名を属性名に
          attr_name = (comment.scan(/\[\[\[(?:attr|attribute)(?:_name)?:\s*?([^\s]+?)\s*?\]\]\]/).flatten.first || col.name)
          comment.gsub!(/\[\[\[.*?\]\]\]/)
          attrs[attr_name] = comment
        end

        column_names = m.columns.map(&:name) - ['id']
        column_order_modeule = Module.new do
          def each_with_column_order(*args, &block)
            @column_names.each do |column_name|
              yield(column_name, self[column_name])
            end
          end

          def self.extended(obj)
            obj.instance_eval do
              alias :each_without_column_order :each
              alias :each :each_with_column_order
            end
          end
        end
        attrs.instance_variable_set(:@column_names, column_names)
        attrs.extend(column_order_modeule)

        # テーブル名(複数形)をモデル名(単数形)に
        model_name = ((m.table_comment || '').scan(/\[\[\[(?:model|class)(?:_name)?:\s*?([^\s]+?)\s*?\]\]\]/).flatten.first || m.name).underscore
        d[model_name] = attrs
        d
      end

      result.instance_eval do
        def each_with_order(*args, &block)
          self.keys.sort.each do |key|
            yield(key, self[key])
          end
        end
        alias :each_without_order :each
        alias :each :each_with_order
      end
      result
    end
  end
end

namespace :i18n do
  namespace :schema_comments do
    task :load_all_models => :environment do
      Dir.glob(File.join(RAILS_ROOT, 'app', 'models', '**', '*.rb')) do |file_name|
        require file_name
      end
    end

    desc "Export i18n model resources from schema_comments. you can set locale with environment variable LOCALE"
    task :export_models => :"i18n:schema_comments:load_all_models" do
      locale = (ENV['LOCALE'] || I18n.locale).to_s
      obj = {locale => {'activerecord' => {'models' => ActiveRecord::Base.export_i18n_models}}}
      puts YAML.dump(obj)
    end

    desc "Export i18n attributes resources from schema_comments. you can set locale with environment variable LOCALE"
    task :export_attributes => :"i18n:schema_comments:load_all_models" do
      locale = (ENV['LOCALE'] || I18n.locale).to_s
      obj = {locale => {'activerecord' => {'attributes' => ActiveRecord::Base.export_i18n_attributes}}}
      puts YAML.dump(obj)
    end

    desc "update i18n YAML. you can set locale with environment variable LOCALE"
    task :update_config_locale => :"i18n:schema_comments:load_all_models" do
      require 'yaml/store'
      locale = (ENV['LOCALE'] || I18n.locale).to_s
      path = (ENV['YAML_PATH'] || File.join(RAILS_ROOT, "config/locales/#{locale}.yml"))
      print "updating #{path}..."

      begin
        db = YAML::Store.new(path)
        db.transaction do
          locale = db[locale] ||= {}
          activerecord = locale['activerecord'] ||= {}
          activerecord['models'] = ActiveRecord::Base.export_i18n_models
          activerecord['attributes'] = ActiveRecord::Base.export_i18n_attributes
        end
        puts "Complete!"
      rescue Exception
        puts "Failure!!!"
        puts $!.to_s
        puts "  " << $!.backtrace.join("\n  ")
        raise
      end
    end
  end
end
