require 'erb'

Capistrano::Configuration.instance.load do
  namespace :db do
    namespace :mongodb do
      desc <<-EOF
      |capistrano-recipes| Performs a compressed database dump. \
      WARNING: This locks your tables for the duration of the mongodump.
      Don't run it madly!
      EOF
      task :dump, :roles => :db, :only => { :primary => true } do
        prepare_from_yaml
        run "mongodump -u #{db_user} -p #{db_pass} -h #{db_host} --port #{db_port} -d #{db_name} #{db_backup_path}" do |ch, stream, out|
          puts out
        end
      end

      desc "|capistrano-recipes| Restores the database from the latest compressed dump"
      task :restore, :roles => :db, :only => { :primary => true } do
        prepare_from_yaml
        run "mongorestore --drop -d #{db_name} #{db_backup_path}/#{db_name}" do |ch, stream, out|
          puts out
        end
      end

      desc "|capistrano-recipes| Downloads the compressed database dump to this machine"
      task :fetch_dump, :roles => :db, :only => { :primary => true } do
        prepare_from_yaml
        download db_remote_file, db_local_file, :via => :scp
      end

      # Sets database variables from remote database.yaml
      def prepare_from_yaml
        set(:db_backup_path) { "#{shared_path}/backup/" }
        set(:db_local_file)  { "tmp/#{db_file}" }
        set(:db_user) { db_config[rails_env]["username"] }
        set(:db_pass) { db_config[rails_env]["password"] }
        set(:db_host) { db_config[rails_env]["host"] }
        set(:db_name) { db_config[rails_env]["database"] }
      end

      def db_config
        @db_config ||= fetch_db_config
      end

      def fetch_db_config
        require 'yaml'
        file = capture "cat #{shared_path}/config/mongoid.yml"
        db_config = YAML.load(file)
      end
    end

    desc "|capistrano-recipes| Create mongoid.yml in shared path with settings for current stage and test env"
    task :create_yaml do
      set(:db_host) { Capistrano::CLI.ui.ask("Enter #{environment} database host:") {|q|q.default = "localhost"} }
      set(:db_port) { Capistrano::CLI.ui.ask("Enter #{environment} database port:", Integer){|q| q.default = 27017 } }
      set(:db_user) { Capistrano::CLI.ui.ask "Enter #{environment} database username:" }
      set(:db_pass) { Capistrano::CLI.password_prompt "Enter #{environment} database password:" }
      set(:db_safe_mode) { Capistrano::CLI.agree "Enable safe mode on #{environment} database? [Yn]:" }

      db_config = ERB.new <<-EOF
      defaults: &defaults
        host: #{db_host}
        port: #{db_port}
        username: #{db_user}
        password: #{db_pass}
        autocreate_indexes: false
        allow_dynamic_fields: true
        include_root_in_json: false
        parameterize_keys: true
        persist_in_safe_mode: #{db_safe_mode}
        raise_not_found_error: true
        reconnect_time: 3

      development:
        <<: *defaults
        database: #{application}-development

      test:
        <<: *defaults
        database: #{application}-test

      production:
        <<: *defaults
        database: #{application}-production
      EOF

      put db_config.result, "#{shared_path}/config/mongoid.yml"
    end
  end

  after "deploy:setup" do
    db.create_yaml if Capistrano::CLI.ui.agree("Create mongoid.yml in app's shared path? [Yn]")
  end
end
