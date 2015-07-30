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
  fail 'error running bundler' unless $?.success? # rubocop:disable Style/SpecialGlobalVars
  gems = `cd #{project_root} && export BUNDLE_WITHOUT=development:test && bundle show `.split("\n")
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
      Dir[File.expand_path("resources/#{type}/**/*", PROJECT_ROOT)] :
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
  File.expand_path("pkg/#{filename}", PROJECT_ROOT)
end

def project_root
  File.dirname(__FILE__)
end

def resource(name)
  File.expand_path("resources/#{name}", PROJECT_ROOT)
end

def tempdir
  Dir.mktmpdir do |dir|
    Dir.chdir(dir) do
      yield(dir)
    end
  end
end
