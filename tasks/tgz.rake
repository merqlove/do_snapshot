require 'digest'

# Used part of Heroku script https://github.com/heroku/heroku
#
file pkg("do_snapshot-#{version}.tgz") => distribution_files('tgz') do |t|
  tempdir do |dir|
    mkchdir('do_snapshot') do
      assemble_distribution
      assemble_gems
      assemble resource('tgz/do_snapshot'), 'bin/do_snapshot', 0755
    end
    ` chmod -R go+r do_snapshot `
    ` tar czf #{t.name} do_snapshot `
  end
end

file pkg("do_snapshot-#{version}.tgz.sha256") => pkg("do_snapshot-#{version}.tgz") do |t|
  File.open(t.name, 'w') do |file|
    file.puts Digest::SHA256.file(t.prerequisites.first).hexdigest
  end
end

task 'tgz:build' => pkg("do_snapshot-#{version}.tgz")
task 'tgz:sign' => pkg("do_snapshot-#{version}.tgz.sha256")

def tgz_signature
  File.read(pkg("do_snapshot-#{version}.tgz.sha256")).chomp
end

task 'tgz:clean' do
  clean pkg("do_snapshot-#{version}.tgz")
end

task 'tgz:release' => %w( tgz:build tgz:sign ) do |t|
  s3_store pkg("do_snapshot-#{version}.tgz"), "do_snapshot/do_snapshot-#{version}.tgz"
  s3_store pkg("do_snapshot-#{version}.tgz"), 'do_snapshot/do_snapshot.tgz'
end
