Capistrano::Configuration.instance.load do
  set :asset_packager, "jammit" unless exists?(:asset_packager)

  namespace :assets do
    desc "Compile Assets with compass"
    task :compass do
      run "cd #{current_path} && bundle exec compass compile; true"
    end

    desc "Package assets"
    task :package do
      run "cd #{current_path} && bundle exec #{asset_packager}; true"
    end
  end
end