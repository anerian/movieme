set :application, "movieme"
set :repository,  "git@github.com:anerian/movieme.git"

# If you aren't deploying to /u/apps/#{application} on the target
# servers (which is the default), you can specify the actual location
# via the :deploy_to variable:
set :deploy_to, "/var/www/apps/#{application}"
set :tmpdir_remote, "/var/www/apps/#{application}/tmp/"
set :tmpdir_local, File.join(File.dirname(__FILE__),'..','tmp')

# If you aren't using Subversion to manage your source code, specify
# your SCM below:
set :scm, :git
set :use_pty, true
set :use_sudo, false
default_run_options[:pty] = true

role :app, "rack1"
role :web, "rack1"
role :db,  "rack1", :primary => true

set :port, 222
set :user, 'deployer'
set :password, 'deployer-deployer'
set :keep_releases, 5
after "deploy:update", "deploy:cleanup"