# coding: utf-8
# frozen_string_literal: true
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'new_adapter/version'

Gem::Specification.new do |spec|
  spec.name          = 'new_adapter'
  spec.version       = NewAdapter::VERSION
  spec.authors       = ['Alexander Merkulov']
  spec.email         = ['sasha@merqlove.ru']
  spec.summary       = 'A NewAdapter for DoSnapshot.'
  spec.description   = 'A NewAdapter for DoSnapshot.'
  spec.homepage      = 'http://dosnapshot.merqlove.ru/'
  spec.license       = 'MIT'

  spec.files = `git ls-files -z`.split("\x0").select { |d| d =~ %r{^(License|README|bin/|data/|ext/|lib/|spec/|test/)} }
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.required_ruby_version = '>= 2.0.0'

  spec.add_dependency 'do_snapshot', '~> 1.0'
end
