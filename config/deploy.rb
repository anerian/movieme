server "moviemeapp", :app, :web, :db, :primary => true

after "deploy:restart", "deploy:search_stop"
after "deploy:restart", "deploy:search_config"
after "deploy:restart", "deploy:search_index"
after "deploy:restart", "deploy:search_start"

namespace :deploy do
  desc "Config Search"
  task :search_config, :roles => :app do
    run "cd #{current_path} && rake ts:config RAILS_ENV=production"
  end

  desc "Start Search"
  task :search_start, :roles => :app do
    run "cd #{current_path} && rake ts:start RAILS_ENV=production"
  end

  desc "Stop Search"
  task :search_stop, :roles => :app do
    run "cd #{current_path} && rake ts:stop RAILS_ENV=production"
  end

  desc "Rebuild Search"
  task :search_rebuild, :roles => :app do
    run "cd #{current_path} && rake ts:stop RAILS_ENV=production"
    run "cd #{current_path} && rake ts:config RAILS_ENV=production"
    run "cd #{current_path} && rake ts:index RAILS_ENV=production"
    run "cd #{current_path} && rake ts:start RAILS_ENV=production"
  end

  desc "Index Search"
  task :search_index, :roles => :app do
    run "cd #{current_path} && rake ts:in RAILS_ENV=production"
  end
end