# config valid for current version and patch releases of Capistrano
lock "~> 3.16.0"

# Change these
server '104.248.210.141', port: 22, roles: [:web, :app, :db], primary: true

set :repo_url,        'git@github.com:raketbizdev/copx.git'
set :application,     'copx'
set :user,            'django'
set :puma_threads,    [4, 16]
set :puma_workers,    0
set :rvm_type, :auto
set :rvm_ruby_version, '2.5.1'

set :rvm_custom_path, '/usr/share/rvm'


# Don't change these unless you know what you're doing
set :pty,             true
set :use_sudo,        false
set :stage,           :production
set :deploy_via,      :remote_cache

set :deploy_to,       "/home/#{fetch(:user)}/sites/#{fetch(:application)}"
set :puma_bind,       "unix://#{shared_path}/tmp/sockets/#{fetch(:application)}-puma.sock"
set :puma_state,      "#{shared_path}/tmp/pids/puma.state"
set :puma_pid,        "#{shared_path}/tmp/pids/puma.pid"
set :puma_access_log, "#{release_path}/log/puma.error.log"
set :puma_error_log,  "#{release_path}/log/puma.access.log"
set :ssh_options,     { forward_agent: true, user: fetch(:user), keys: %w(~/.ssh/id_rsa.pub) }
set :puma_preload_app, true
set :puma_worker_timeout, nil
set :puma_init_active_record, true  # Change to false when not using ActiveRecord
append :linked_files, "config/master.key"

# sudo ln -nfs "/home/django/sites/copx/current/config/nginx.conf" "/etc/nginx/sites-enabled/copx.ideamakr.com.conf"

## Defaults:
# set :scm,           :git
set :branch, fetch(:branch, "dev")
# set :dev
# set :format,        :pretty
# set :log_level,     :debug
# set :keep_release
## Linked Files & Directories (Default None):
# set :linked_files, %w{config/database.yml}
set :linked_dirs,  %w{bin log tmp/pids tmp/cache tmp/sockets vendor/bundle public/system}

namespace :puma do
  desc 'Create Directories for Puma Pids and Socket'
  task :make_dirs do
    on roles(:app) do
      execute "mkdir #{shared_path}/tmp/sockets -p"
      execute "mkdir #{shared_path}/tmp/pids -p"
    end
  end

  before :start, :make_dirs
end

namespace :deploy do
  desc "Make sure local git is in sync with remote."
  task :check_revision do
    on roles(:app) do
      unless `git rev-parse HEAD` == `git rev-parse origin/dev`
        puts "WARNING: HEAD is not the same as origin/dev"
        puts "Run `git push` to sync changes."
        exit
      end
    end
  end

  desc 'Initial Deploy'
  task :initial do
    on roles(:app) do
      before 'deploy:restart', 'puma:start'
      invoke 'deploy'
    end
  end

  desc 'Restart application'
  task :restart do
    on roles(:app), in: :sequence, wait: 5 do
      invoke 'puma:restart'
    end
  end
  # desc 'Simplify image uploads'
  # task :symlink_config, roles: :app do
  #   run "ln -nfs #{shared_path}/uploads #{release_path}/public/uploads"
  # end

  # desc "Add User from Rake task `cap production deploy:add_user task=user:add_user`"
  # # cap production deploy:add_user task=user:add_user
  # # cap deploy rake:invoke task=user:add_user
  # # bundle exec rake user:add_user RAILS_ENV=production
  # bundle exec rails console RAILS_ENV=production
  # task :add_user do
  #   on roles(:app) do 
  #     execute "cd #{deploy_to}/current"
  #     execute "bundle exec rake #{ENV['task']} RAILS_ENV=#{fetch(:stage)}"
  #   end
  # end

  desc 'Add User from Rake task `cap production deploy:add_user task=user:add_user`'
  task add_user: [:set_rails_env] do
    on fetch(:migration_servers) do
      within release_path do
        with rails_env: fetch(:stage) do
          execute :rake, 'user:add_user'
        end
      end
    end
  end



  before :starting,     :check_revision
  after  :finishing,    :compile_assets
  after  :finishing,    :cleanup
  after  :finishing,    :restart
end

# namespace :user do
#   desc "Add User Admin"
#   task :invoke do
#     run("cd #{deploy_to}/current && ~/.rvm/bin/rvm bundle exec rake user:add_user RAILS_ENV=production") 
#     # run("RAILS_ENV=production rake user:add_user")
#   end

  # task :restart_sidekiq do
  #   on roles(:worker) do
  #     execute :service, "sidekiq restart"
  #   end
  # end
  # after "deploy:published", "restart_sidekiq"

# end



# namespace :cron do  
#   desc "run Crontab e"  
#   # run like: cap production deploy rake:data task=add_location  
#   # RAILS_ENV=production rake data:add_location
#   task :run_cron do  
#     run("crontab -e")
#     run("15 * * * * cd #{deploy_to}/current && ~/.rvm/bin/rvm RAILS_ENV=production rake auto_status:undeliver") 
#   end  
# # end

# namespace :rake do
#   desc "Invoke rake task"
#   # cap production deploy rake:invoke task=user:add_user
#   # cap deploy rake:invoke task=user:add_user
#   task :invoke do
#     run "cd #{deploy_to}/current"
#     run "bundle exec rake #{ENV['task']} RAILS_ENV=#{rails_env}"
#   end
# end
# ps aux | grep puma    # Get puma pid
# kill -s SIGUSR2 pid   # Restart puma
# kill -s SIGTERM pid   # Stop puma
# sudo ln -nfs "/home/django/sites/copx/current/config/nginx.conf" "/etc/nginx/sites-enabled/iokos"
# bundle exec rails console -e production
# sudo systemctl restart nginx.service
# sudo systemctl status nginx.service
# sudo certbot --nginx -d iokos.ph -d warranty.iokos.com
# sudo certbot certonly --webroot --webroot-path=/home/django/sites/copx/current/public -d copx.ideamakr.com
# RAILS_ENV=production bundle exec rails console