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

  spec.required_ruby_version = '>= 2.0.0'

  spec.add_dependency 'droplet_kit', '~> 2.1.0'
  spec.add_dependency 'thor', '~> 0.19'
  spec.add_dependency 'pony', '~> 1.1'
end
