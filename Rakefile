# -*- encoding : utf-8 -*-
# rubocop:disable Style/CaseIndentation
# rubocop:disable Style/MethodLength
# rubocop:disable Lint/UselessAssignment
# rubocop:disable Lint/ShadowingOuterLocalVariable
# rubocop:disable Style/MultilineTernaryOperator
# rubocop:disable Lint/HandleExceptions
require 'rubygems'

PROJECT_ROOT = File.expand_path('..', __FILE__)
$LOAD_PATH.unshift "#{PROJECT_ROOT}/lib"

require 'do_snapshot/version'
begin
  require 'rspec/core/rake_task'

  desc 'Run all specs'
  RSpec::Core::RakeTask.new(:spec)
rescue LoadError
  # The test gem group fails to install on the platform for some reason
end

task default: :spec

# Used part of Heroku script https://github.com/heroku/heroku
#
require 'erb'
require 'fileutils'
require 'tmpdir'

def assemble(source, target, perms = 0644)
  FileUtils.mkdir_p(File.dirname(target))
  File.open(target, 'w') do |f|
    f.puts ERB.new(File.read(source)).result(binding)
  end
  File.chmod(perms, target)
end

def assemble_distribution(target_dir = Dir.pwd)
  distribution_files.each do |source|
    target = source.gsub(/^#{project_root}/, target_dir)
    FileUtils.mkdir_p(File.dirname(target))
    FileUtils.cp(source, target)
  end
end

GEM_BLACKLIST = %w( bundler do_snapshot )

def assemble_gems(target_dir = Dir.pwd)
  lines = `cd #{project_root} && bundle show `.strip.split("\n")
  fail 'error running bundler' unless $?.success?
  gems = `cd #{project_root} && export BUNDLE_WITHOUT=development && bundle show `.split("\n")
  gems.each do |line|
    next unless line =~ /^  \* (.*?) \((.*?)\)/
    next if GEM_BLACKLIST.include?(Regexp.last_match[1])
    puts "vendoring: #{Regexp.last_match[1]}-#{Regexp.last_match[2]}"
    gem_dir = ` cd #{project_root} && bundle show #{Regexp.last_match[1]} `.strip
    FileUtils.mkdir_p "#{target_dir}/vendor/gems"
    ` cp -R "#{gem_dir}" "#{target_dir}/vendor/gems" `
  end.compact
end

def clean(file)
  rm file if File.exist?(file)
end

def distribution_files(type = nil)
  require 'do_snapshot/distribution'
  base_files = DoSnapshot::Distribution.files
  type_files = type ?
      Dir[File.expand_path("../dist/resources/#{type}/**/*", __FILE__)] :
      []
  # base_files.concat(type_files)
  base_files
end

def mkchdir(dir)
  FileUtils.mkdir_p(dir)
  Dir.chdir(dir) do |dir|
    yield(File.expand_path(dir))
  end
end

def pkg(filename)
  FileUtils.mkdir_p('pkg')
  File.expand_path("../pkg/#{filename}", __FILE__)
end

def project_root
  File.dirname(__FILE__)
end

def resource(name)
  File.expand_path("../dist/resources/#{name}", __FILE__)
end

def s3_connect
  return if @s3_connected

  require 'aws/s3'

  unless ENV['AWS_ACCESS_KEY_ID'] && ENV['AWS_SECRET_ACCESS_KEY']
    puts 'please set AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY in your environment'
    exit 1
  end

  AWS::S3::Base.establish_connection!(
      access_key_id: ENV['AWS_ACCESS_KEY_ID'],
      secret_access_key: ENV['AWS_SECRET_ACCESS_KEY']
  )

  @s3_connected = true
end

def store(package_file, filename, bucket = 'assets.merqlove.ru')
  s3_connect
  puts "storing: #{filename}"
  AWS::S3::S3Object.store(filename, File.open(package_file), bucket, access: :public_read)
end

def tempdir
  Dir.mktmpdir do |dir|
    Dir.chdir(dir) do
      yield(dir)
    end
  end
end

def version
  require 'do_snapshot/version'
  DoSnapshot::VERSION
end

Dir[File.expand_path('../dist/**/*.rake', __FILE__)].each do |rake|
  import rake
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

desc 'Check current ci status and/or wait for build to finish.'
task 'ci' do
  poll_ci
end

desc 'Release the latest version'
task 'release' => %w( gem:release tgz:release zip:release manifest:update ) do
  puts("Released v#{version}")
end
