Capistrano::Configuration.instance.load do
  namespace :push_deploy do
    set(:push_deploy_repo) { "/home/#{user}/code/#{application}"}
    desc "setup everything to deploy via push"
    task :setup, :roles => :app  do
      server = roles[:app].servers.first

      origin = Capistrano::CLI.ui.ask("Enter repository url to clone:")

      run "rm -rf #{push_deploy_repo}"
      run "mkdir -p ~/code"
      run "git clone --depth=1 #{origin} #{push_deploy_repo}"
      run "cd #{push_deploy_repo} && git config receive.denyCurrentBranch ignore"

      repo_url = "#{user}\@#{server}:#{push_deploy_repo}"

      hook = %@#!/bin/bash
cd ..
GIT_DIR=$(pwd)/.git
git reset --hard master
git update-server-info
unset GIT_DIR

bundle install
cap #{environment} deploy
@
      hook_path = "#{push_deploy_repo}/.git/hooks/post-receive"
      put hook, hook_path
      run "chmod 755 #{hook_path}"

      run "cd #{current_path} && git remote rm origin && git remote add origin #{repo_url}"

      puts %@

== Instructions

add deploy repository to your remotes

  git remote add deploy #{repo_url}

add this to your deploy.rb

  set :repository, "#{repo_url}"
  set :branch, "origin/master"

to deploy a branch just type:

  git push deploy your_branch:master -f
@
    end
  end
end
