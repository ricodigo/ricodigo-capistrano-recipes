Capistrano::Configuration.instance.load do
  set(:magent_queue, :default) unless exists?(:magent_queue)
  set(:magent_grace_time, 120) unless exists?(:magent_grace_time)
  set(:magent_local_config) { "#{templates_path}/magent.bluepill.erb" } unless exists?(:magent_local_config)
  set(:magent_remote_config) { "#{shared_path}/config/pills/magent.pill" } unless exists?(:magent_remote_config)

  namespace :magent do
    desc "Configure magent pill"
    task :setup do
      generate_config(magent_local_config, magent_remote_config)
    end

    desc "Init magent with bluepill"
    task :init do
      rvmsudo "bluepill load #{magent_remote_config}"
    end

    desc "Start magent with bluepill"
    task :start do
      rvmsudo "bluepill magent start"
    end

    desc "Restart magent with bluepill"
    task :restart do
      rvmsudo "bluepill magent restart"
    end

    desc "Stop magent with bluepill"
    task :stop do
      rvmsudo "bluepill magent stop"
    end

    desc "Display the bluepill status"
    task :status do
      rvmsudo "bluepill magent status"
    end

    desc "Stop magent and quit bluepill"
    task :quit do
      rvmsudo "bluepill magent stop"
      rvmsudo "bluepill magent quit"
    end
  end
end
