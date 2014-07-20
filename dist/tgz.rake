# Used part of Heroku script https://github.com/heroku/heroku
#
file pkg("do_snapshot-#{version}.tgz") => distribution_files("tgz") do |t|
  tempdir do |dir|
    mkchdir("do_snapshot") do
      assemble_distribution
      assemble_gems
      assemble resource("tgz/do_snapshot"), "bin/do_snapshot", 0755
    end

    sh "chmod -R go+r do_snapshot"
    sh "sudo chown -R 0:0 do_snapshot"
    sh "tar czf #{t.name} do_snapshot"
    sh "sudo chown -R $(whoami) do_snapshot"
  end
end

task "tgz:build" => pkg("do_snapshot-#{version}.tgz")

task "tgz:clean" do
  clean pkg("do_snapshot-#{version}.tgz")
end

task "tgz:release" => "tgz:build" do |t|
  store pkg("do_snapshot-#{version}.tgz"), "do_snapshot/do_snapshot-#{version}.tgz"
  store pkg("do_snapshot-#{version}.tgz"), "do_snapshot/do_snapshot.tgz"
end
