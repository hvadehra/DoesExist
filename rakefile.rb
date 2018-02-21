APP_NAME='some-app'
RELEASE_BRANCH='master'

$: << File.dirname(__FILE__)

require 'rubygems'
require 'rake'
require 'jenkins_api_client'

STDIN.sync=true; STDOUT.sync=true

namespace :git do
    task :update do
        res = `git diff "origin/#{RELEASE_BRANCH}"`.strip
        puts res
        if res != ''
            error("not in sync with remote")
        end
    end
end

task :release do
    cur_branch = `git rev-parse --abbrev-ref HEAD`.strip
    if cur_branch == "#{RELEASE_BRANCH}"
        puts "releasing from #{cur_branch}"
        invoke_task "git:update"
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

