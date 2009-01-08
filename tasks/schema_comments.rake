require 'yaml'
require 'yaml_waml'
require 'activerecord'

class ActiveRecord::Base
  class << self
      attr_accessor_with_default :ignore_pattern_to_export_i18n, /\[.*\]/
      
      def export_i18n_models
        subclasses = ActiveRecord::Base.send(:subclasses).select do |klass|
          (klass != SchemaComments::SchemaComment) and
            klass.respond_to?(:table_exists?) and klass.table_exists?
        end
        subclasses.inject({}) do |d, m|
          comment = m.table_comment
          comment.gsub!(ignore_pattern_to_export_i18n, '') if ignore_pattern_to_export_i18n
          d[m.name.underscore] = comment
          d
        end
      end
      
      def export_i18n_attributes
        subclasses = ActiveRecord::Base.send(:subclasses).select do |klass|
          (klass != SchemaComments::SchemaComment) and
            klass.respond_to?(:table_exists?) and klass.table_exists?
        end
        subclasses.inject({}) do |d, m|
          attrs = {}
          m.columns.each do |col|
            next if col.name == 'id'
            comment = (col.comment || '').dup
            comment.gsub!(ignore_pattern_to_export_i18n, '') if ignore_pattern_to_export_i18n
            attrs[col.name] = comment
          end
          d[m.name.underscore] = attrs
          d
        end
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
    
    desc "Export i18n model resources from schema_comments"
    task :export_models => :"i18n:schema_comments:load_all_models" do
      obj = {I18n.locale => {'activerecord' => {'models' => ActiveRecord::Base.export_i18n_models}}}
      puts YAML.dump(obj)
    end
    
    desc "Export i18n attributes resources from schema_comments"
    task :export_models => :"i18n:schema_comments:load_all_models" do
      obj = {I18n.locale => {'activerecord' => {'attributes' => ActiveRecord::Base.export_i18n_attributes}}}
      puts YAML.dump(obj)
    end
  end
end
