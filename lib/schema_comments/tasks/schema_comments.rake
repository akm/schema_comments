namespace :schema_comments do
  desc 'Dump schema to db/schema.rb'
  task :dump => :environment do
    require 'active_record/schema_dumper'
    filename = ENV['SCHEMA'] || Rails.root.join('db/schema.rb').to_s
    File.open(filename, "w:utf-8") do |file|
      ActiveRecord::Base.establish_connection(Rails.env)
      # ActiveRecord::SchemaDumper.dump(ActiveRecord::Base.connection, file)
      SchemaComments::SchemaDumper.dump(ActiveRecord::Base.connection, file)
    end
  end

  namespace :i18n do
    desc "Show locale YAML"
    task :show => :environment do
      locale = (ENV['LOCALE'] || I18n.locale).to_s
      puts SchemaComments::SchemaComment.locale_yaml(locale)
    end

    desc "update i18n YAML. you can set locale with environment variable LOCALE"
    task :update => :environment do
      locale = (ENV['LOCALE'] || I18n.locale).to_s
      path = (ENV['YAML_PATH'] || Rails.root.join("config/locales/#{locale}.yml"))
      open(path, 'w') do |f|
        f.puts SchemaComments::SchemaComment.locale_yaml(locale)
      end
    end

  end
end

if Rails.env.development?
  Rake::Task['db:schema:dump'].enhance do
    Rake::Task['schema_comments:dump'].invoke
  end
end
