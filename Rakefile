# -*- encoding : utf-8 -*-
require 'bundler/setup'

PROJECT_ROOT = File.expand_path('..', __FILE__)
PROJECT_ROOT_DIR = File.dirname(__FILE__)
$:.unshift "#{PROJECT_ROOT}/lib"
require 'do_snapshot'

begin
  require 'rspec/core/rake_task'

  desc 'Run all specs'
  RSpec::Core::RakeTask.new(:spec)
rescue LoadError
  # The test gem group fails to install on the platform for some reason
end

task default: :spec

def version
  DoSnapshot::VERSION
end

def poll_ci
  require 'json'
  require 'net/http'
  uri = URI.parse('https://api.travis-ci.org/repositories/merqlove/do_snapshot.json')
  travis = Net::HTTP.get_response(uri)
  data = JSON.parse(travis.body)
  case data['last_build_status']
  when nil
    print('.')
    sleep(1)
    poll_ci
  when 0
    puts('SUCCESS')
  when 1
    puts('FAILURE')
  end
end

Dir.glob('tasks/helpers/*.rb').each { |r| import r }
Dir.glob('tasks/*.rake').each { |r| import r }

desc 'clean'
task :clean do
  rm_r 'pkg'
  mkdir 'pkg'
end

desc 'Release the latest version'
task 'release' => %w( ci gem:release git:release tgz:release zip:release brew:release manifest:update ) do
  puts("Released v#{version}")
end

desc 'Check current ci status and/or wait for build to finish.'
task 'ci' do
  poll_ci
end
