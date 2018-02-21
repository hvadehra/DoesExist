
$: << File.dirname(__FILE__)

require 'rubygems'
require 'rake'
require 'jenkins_api_client'
require 'json'

STDIN.sync=true; STDOUT.sync=true

USER_CONFIG=JSON.parse(File.read(File.expand_path("~/.omsrakeconfig", __FILE__)))
APP_CONFIG=JSON.parse(File.read(".apprakeconfig"))

namespace :git do
    task :check_remote_diff do
        diff = `git diff "origin/#{release_branch}"`.strip
        if !diff.empty?
            error("not in sync with remote")
        end
    end

    task :push do
        puts "pushing to remote"
        system("git push")
    end

    task :merge_into_dev_branch do
        puts "merging from #{release_branch} into #{dev_branch}"
        if system("git checkout #{dev_branch}")
            if system("git merge --no-ff -m \"Merge remote-tracking branch origin/#{release_branch}\" origin/#{release_branch}")
                invoke_task "git:push"
            else
                error("failed to merge from origin/#{release_branch}")
            end
        else
            error("failed to checkout #{dev_branch}")
        end
    end

    task :merge_from_dev_branch do
        puts "merging from #{dev_branch} into #{release_branch}"
        if system("git merge --no-ff -m \"Merge remote-tracking branch origin/#{dev_branch}\" origin/#{dev_branch}")
            invoke_task "git:push"
        else
            error("failed to merge from origin/#{dev_branch}")
        end
    end

end

namespace :mvn do
    task :release do
        puts "performing release"
        rls_success = system("mvn -Darguments=\"-DskipTests\" release:prepare release:perform")
        if !rls_success
            error("release failed")
        end
    end
end

namespace :jenkins do
  task :setup do
    @client = JenkinsApi::Client.new(:server_ip => jenkins_host, :username => jenkins_username, :password => jenkins_password)
  end
end

task :release do
    cur_branch = `git rev-parse --abbrev-ref HEAD`.strip
    if cur_branch == "#{release_branch}"
        invoke_task "git:check_remote_diff"
        invoke_task "git:merge_from_dev_branch"
        invoke_task "mvn:release"
        invoke_task "git:push"
        invoke_task "git:merge_into_dev_branch"
    else
        error("not in release branch")
    end
end

task :build => ["jenkins:setup"] do

end

def error(msg)
 raise "*** ERROR: #{msg}"
end

def invoke_task task
  Rake::Task[task].reenable
  Rake::Task[task].invoke
end

def dev_branch
    return APP_CONFIG["dev_branch"]
end

def release_branch
    return APP_CONFIG["release_branch"]
end

def jenkins_host
    return APP_CONFIG["jenkins_url"]
end

def jenkins_username
    return USER_CONFIG["username"]
end

def jenkins_password
    return USER_CONFIG["password"]
end

