# Used part of Heroku script https://github.com/heroku/heroku
#
require 'zip'
require 'digest'

file pkg("do_snapshot-#{version}.zip") => distribution_files("zip") do |t|
  tempdir do |dir|
    mkchdir("do_snapshot") do
      assemble_distribution
      assemble_gems
      assemble resource("tgz/do_snapshot"), "bin/do_snapshot", 0755
      Zip::File.open(t.name, Zip::File::CREATE) do |zip|
        Dir["**/*"].each do |file|
          zip.add(file, file) { true }
        end
      end
    end
  end
end

file pkg("do_snapshot-#{version}.zip.sha256") => pkg("do_snapshot-#{version}.zip") do |t|
  File.open(t.name, "w") do |file|
    file.puts Digest::SHA256.file(t.prerequisites.first).hexdigest
  end
end

task "zip:build" => pkg("do_snapshot-#{version}.zip")
task "zip:sign"  => pkg("do_snapshot-#{version}.zip.sha256")

def zip_signature
  File.read(pkg("do_snapshot-#{version}.zip.sha256")).chomp
end

task "zip:clean" do
  clean pkg("do_snapshot-#{version}.zip")
end

task "zip:release" => %w( zip:build zip:sign ) do |t|
  store pkg("do_snapshot-#{version}.zip"), "do_snapshot/do_snapshot-#{version}.zip"
  store pkg("do_snapshot-#{version}.zip"), "do_snapshot/do_snapshot.zip"
end
