Capistrano::Configuration.instance.load do
  set(:bluepill_local_config) { "#{templates_path}/app.bluepill.erb" } unless exists?(:nginx_local_config)
  set(:bluepill_remote_config) { "#{shared_path}/config/pills/#{application}.conf" } unless exists?(:nginx_remote_config)

  namespace :bluepill do
    desc "|capistrano-recipes| Parses and uploads nginx configuration for this app."
    task :setup, :roles => :app , :except => { :no_release => true } do
      generate_config(bluepill_local_config, bluepill_remote_config)
    end

    desc "|capistrano-recipes| Install the bluepill monitoring tool"
    task :install, :roles => [:app] do
      sudo "gem install bluepill"
    end

    desc "|capistrano-recipes| Stop processes that bluepill is monitoring and quit bluepill"
    task :quit, :roles => [:app] do
      args = exists?(:options) ? options : ''
      begin
        sudo "bluepill stop #{args}"
      rescue
        puts "Bluepill was unable to finish gracefully all the process"
      ensure
        sudo "bluepill quit"
      end
    end

    desc "|capistrano-recipes| Load the pill from {your-app}/config/pills/{app-name}.pill"
    task :init, :roles =>[:app] do
      sudo "RAILS_ROOT=#{current_path} bluepill load #{current_path}/config/pills/#{application}.pill"
    end

    desc "|capistrano-recipes| Starts your previous stopped pill"
    task :start, :roles =>[:app] do
      args = exists?(:options) ? options : ''
      sudo "bluepill start #{args}"
    end

    desc "|capistrano-recipes| Stops some bluepill monitored process"
    task :stop, :roles =>[:app] do
      args = exists?(:options) ? options : ''
      sudo "bluepill stop #{args}"
    end

    desc "|capistrano-recipes| Restarts the pill from {your-app}/config/pills/{app-name}.pill"
    task :restart, :roles =>[:app] do
      args = exists?(:options) ? options : ''
      sudo "bluepill restart #{args}"
    end

    desc "|capistrano-recipes| Prints bluepills monitored processes statuses"
    task :status, :roles => [:app] do
      args = exists?(:options) ? options : ''
      sudo "bluepill status #{args}"
    end
  end

  after 'deploy:setup' do
    bluepill.install if Capistrano::CLI.ui.agree("Do you want to install the bluepill monitor? [Yn]")
    bluepill.setup if Capistrano::CLI.ui.agree("Create nginx configuration file? [Yn]")
  end if is_using('bluepill', :monitorer)
end