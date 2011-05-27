Capistrano::Configuration.instance.load do
  namespace :push_deploy do
    set(:push_deploy_repo) { "/home/#{user}/code/#{application}"}
    desc "setup everything to deploy via push"
    task :setup, :roles => :app  do
      server = roles[:app].servers.first

      run "rm -rf #{push_deploy_repo}"
      run "mkdir -p ~/code"
      run "git clone #{repository} #{push_deploy_repo}"
      run "cd #{push_deploy_repo} && git config receive.denyCurrentBranch ignore"

      hook = %@#!/bin/bash
cd ..
GIT_DIR=$(pwd)/.git
git reset --hard HEAD
unset GIT_DIR

bundle install
cap #{environment} deploy
@
      hook_path = "#{push_deploy_repo}/.git/hooks/post-receive"
      put hook, hook_path
      run "chmod 755 #{hook_path}"

      puts %@

== Instructions

add deploy repository to your remotes

  git remote add deploy #{user}\@#{server}:#{push_deploy_repo}

add this to your deploy.rb

  set :repository, "#{user}\@#{server}:#{push_deploy_repo}"

to deploy a branch just type:

  git push deploy your_branch:master -f
@
    end
  end
end
