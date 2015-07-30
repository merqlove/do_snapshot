# Used part of Heroku script https://github.com/heroku/heroku
#
file pkg("do_snapshot-#{version}.gem") => distribution_files('gem') do |t|
  sh 'gem build do_snapshot.gemspec'
  sh "mv do_snapshot-#{version}.gem #{t.name}"
end

task 'gem:build' => pkg("do_snapshot-#{version}.gem")

task 'gem:clean' do
  clean pkg("do_snapshot-#{version}.gem")
end

task 'gem:release' => 'gem:build' do |t|
  sh "gem push #{pkg("do_snapshot-#{version}.gem")}"
end
