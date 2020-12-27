require 'bundler/capistrano'

set :application, "earth"
set :repository,  "git@github.centtech.com:DV/earth.git"

set :scm, :git

role :web, "dv-121-5.centtech.com"                                   # Your HTTP server, Apache/etc
role :app, "dv-121-5.centtech.com"                                   # This may be the same as your `Web` server

set :user, "balance"
set :use_sudo, false

# if you're still using the script/reaper helper you will need
# these http://github.com/rails/irs_process_scripts

# If you are using Passenger mod_rails uncomment this:
namespace :deploy do
  task :start, :roles => :app, :except => { :no_release => true } do
    run "#{try_sudo} touch #{File.join(current_path,'tmp','restart.txt')}"
  end
  task :stop do ; end
  task :restart, :roles => :app, :except => { :no_release => true } do
    run "#{try_sudo} touch #{File.join(current_path,'tmp','restart.txt')}"
  end
end


set :deploy_to, "/n/dv/release/earth"

set :normalize_asset_timestamps, false
