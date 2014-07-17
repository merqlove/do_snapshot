# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'do_snapshot/version'

Gem::Specification.new do |spec|
  spec.name          = 'do_snapshot'
  spec.version       = DoSnapshot::VERSION
  spec.authors       = ['Alexander Merkulov']
  spec.email         = ['sasha@merqlove.ru']
  spec.summary       = %q{Snapshot creator for Digital Ocean droplets. Multi-threading inside. Use it with Cron or other tools.}
  spec.description   = %q{Snapshot creator for Digital Ocean droplets. Multi-threading inside. Use it with Cron or other tools.}
  spec.homepage      = 'http://github.com/merqlove/do_snapshot'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_dependency 'digitalocean', '~> 1.2'
  spec.add_dependency 'thor'
  spec.add_dependency 'pony'

  spec.add_development_dependency 'bundler', '~> 1.6'
  spec.add_development_dependency 'rake'
end
