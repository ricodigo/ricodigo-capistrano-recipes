Capistrano::Configuration.instance.load do
  set(:bluepill_local_config) { "#{templates_path}/app.bluepill.erb" } unless exists?(:bluepill_local_config)
  set(:bluepill_remote_config) { "#{shared_path}/config/pills/#{application}.pill" } unless exists?(:bluepill_remote_config)

  namespace :bluepill do
    desc "|capistrano-recipes| Parses and uploads bluepill configuration for this app."
    task :setup, :roles => :app , :except => { :no_release => true } do
      generate_config(bluepill_local_config, bluepill_remote_config)
    end

    desc "|capistrano-recipes| Parses and uploads a bluepill template."
    task :template, :roles => :app , :except => { :no_release => true } do
      generate_config("#{templates_path}/template.bluepill.erb", "#{shared_path}/config/pills/template.pill")
    end

    desc "|capistrano-recipes| Install the bluepill monitoring tool"
    task :install, :roles => [:app] do
      sudo "gem install bluepill"
    end

    desc "|capistrano-recipes| Stop processes that bluepill is monitoring and quit bluepill"
    task :quit, :roles => [:app] do
      args = exists?(:options) ? options : ''
      begin
        rvmsudo "bluepill stop #{args}"
      rescue
        puts "Bluepill was unable to finish gracefully all the process"
      ensure
        rvmsudo "bluepill quit"
      end
    end

    desc "|capistrano-recipes| Load the pill from {your-app}/config/pills/{app-name}.pill"
    task :init, :roles =>[:app] do
      rvmsudo "bluepill load #{shared_path}/config/pills/#{application}.pill"
    end

    desc "|capistrano-recipes| Starts your previous stopped pill"
    task :start, :roles =>[:app] do
      args = exists?(:options) ? options : ''
      app = exists?(:app) ? app : application
      rvmsudo "bluepill #{app} start #{args}"
    end

    desc "|capistrano-recipes| Stops some bluepill monitored process"
    task :stop, :roles =>[:app] do
      args = exists?(:options) ? options : ''
      app = exists?(:app) ? app : application
      rvmsudo "bluepill #{app} stop #{args}"
    end

    desc "|capistrano-recipes| Restarts the pill from {your-app}/config/pills/{app-name}.pill"
    task :restart, :roles =>[:app] do
      args = exists?(:options) ? options : ''
      app = exists?(:app) ? app : application
      rvmsudo "bluepill #{app} restart #{args}"
    end

    desc "|capistrano-recipes| Prints bluepills monitored processes statuses"
    task :status, :roles => [:app] do
      args = exists?(:options) ? options : ''
      app = exists?(:app) ? app : application
      rvmsudo "bluepill #{app} status #{args}"
    end
  end

  after 'deploy:setup' do
    bluepill.install if Capistrano::CLI.ui.agree("Do you want to install the bluepill monitor? [Yn]")
    bluepill.setup if Capistrano::CLI.ui.agree("Create bluepill configuration file? [Yn]")
  end if is_using('bluepill', :monitorer)
end