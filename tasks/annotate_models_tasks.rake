# Original file
# http://github.com/rotuka/annotate_models/blob/d2afee82020dbc592b147d92f9beeadbf665a9e0/tasks/annotate_models_tasks.rake
namespace :db do
  desc "Add schema information (as comments) to model files"
  task :annotate do
    require File.join(File.dirname(__FILE__), "../lib/annotate_models.rb")
    AnnotateModels.do_annotations
  end
 
  desc "Updates database (migrate and annotate models)"
  task :update => %w(migrate annotate)
end
