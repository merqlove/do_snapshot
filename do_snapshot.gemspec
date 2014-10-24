# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'do_snapshot/version'

Gem::Specification.new do |spec|
  spec.name          = 'do_snapshot'
  spec.version       = DoSnapshot::VERSION
  spec.authors       = ['Alexander Merkulov']
  spec.email         = ['sasha@merqlove.ru']
  spec.summary       = 'A command-line snapshot maker for your DigitalOcean droplets. Fully Automated. Multi-threaded.'
  spec.description   = 'Snapshot creator for Digital Ocean droplets. Multi-threading inside. Auto-cleanup feature. No matter how much droplets you have. Cron optimized.'
  spec.homepage      = 'http://dosnapshot.merqlove.ru/'
  spec.license       = 'MIT'

  spec.files = `git ls-files -z`.split("\x0").select { |d| d =~ %r{^(License|README|bin/|data/|ext/|lib/|spec/|test/)} }
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_dependency 'digitalocean', '~> 1.2'
  spec.add_dependency 'thor', '~> 0.19'
  spec.add_dependency 'pony', '~> 1.1'

  spec.add_development_dependency 'rake', '>= 0.8.7'
  spec.add_development_dependency 'json'
  spec.add_development_dependency 'rubocop', '>= 0.24'
  spec.add_development_dependency 'rspec', '>= 3.1'
  spec.add_development_dependency 'rspec-core', '>= 3.1'
  spec.add_development_dependency 'rspec-expectations', '>= 3.1'
  spec.add_development_dependency 'rspec-mocks', '>= 3.1'
  spec.add_development_dependency 'webmock', '>= 1.18'
  spec.add_development_dependency 'coveralls', '>= 0.7'
  spec.add_development_dependency 'rubyzip'
  spec.add_development_dependency 's3'
end
