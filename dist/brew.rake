task "brew:release" => pkg("do_snapshot-#{version}.tgz.sha256") do |t|
  sha256 = File.read(t.source).strip
  tempdir do |dir|
    dest = 'homebrew-do-snapshot'
    cd = "cd #{dest}"

    sh "git clone git@github.com:merqlove/homebrew-do-snapshot.git #{dest}"
    formula = File.read('homebrew-do-snapshot/do_snapshot.rb')
    release = formula.gsub(/(url.+)-([0-9.-_]+)(\.tgz)/, "\\1-#{version}.tgz")
              .gsub(/(sha256\s).*/, "\\1'#{sha256}'")
    File.open("#{dest}/do_snapshot.rb", 'w') do |f|
      f.write release
    end

    # Push into repo
    sh "#{cd} && git add ."
    sh "#{cd} && git commit -m 'Version bump'"
    sh "#{cd} && git tag v#{version}"
    sh "#{cd} && git push origin master --tags"
  end
end
