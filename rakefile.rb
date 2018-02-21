APP_NAME='some-app'
RELEASE_BRANCH='master'

$: << File.dirname(__FILE__)

require 'rubygems'
require 'rake'
require 'jenkins_api_client'

STDIN.sync=true; STDOUT.sync=true

namespace :git do
    task :check_remote_diff do
        diff = `git diff "origin/#{RELEASE_BRANCH}"`.strip
        if !diff.empty?
            error("not in sync with remote")
        end
    end
end

namespace :mvn do
    task :release do
        puts "performing release"
        rls_success = system("mvn clean release:prepare release:perform")
        if !rls_success?
            error("release failed")
        end
    end
end

task :release do
    cur_branch = `git rev-parse --abbrev-ref HEAD`.strip
    if cur_branch == "#{RELEASE_BRANCH}"
        invoke_task "git:check_remote_diff"
        invoke_task "mvn:release"
    else
        error("not in release branch")
    end
end

def error(msg)
 raise "*** ERROR: #{msg}"
end

def invoke_task task
  Rake::Task[task].reenable
  Rake::Task[task].invoke
end

