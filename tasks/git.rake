task 'git:release' do |t|
  sh "git tag v#{version}"
  sh 'git push origin master --tags'
end
