Capistrano::Configuration.instance.load do
  namespace :magent do
    task :start do
      run "export RAILS_ENV=#{rails_env}; cd #{current_path}; bundle exec magent -d -Q default -l #{current_path}/log -P #{current_path}/tmp/pids start; true"
    end

    task :restart do
      run "export RAILS_ENV=#{rails_env}; cd #{current_path}; bundle exec magent -d -Q default -l #{current_path}/log -P #{current_path}/tmp/pids restart; true"
    end

    task :stop do
      run "export RAILS_ENV=#{rails_env}; cd #{current_path}; bundle exec magent -d -Q default -l #{current_path}/log -P #{current_path}/tmp/pids stop; true"
    end
  end
end
