# -*- encoding : utf-8 -*-
require 'coveralls'
Coveralls.wear! do
  add_filter '/spec/*'
end

require 'do_snapshot/cli'
require 'webmock/rspec'
require 'fileutils'
require 'digitalocean_c'
require_relative 'shared/api_helpers'
require_relative 'shared/api_v1_helpers'
require_relative 'shared/api_v2_helpers'
require_relative 'shared/uri_helpers'
require_relative 'shared/environment'
require 'do_snapshot/core_ext/hash'

WebMock.disable_net_connect!(allow_localhost: true)
WebMock.disable!(except: [:net_http])

Dir.glob(::File.expand_path('../support/*.rb', __FILE__)).each { |f| require_relative f }

RSpec.configure do |config|
  # Pretty tests
  config.color = true
  config.order = :random
  config.mock_with :rspec do |mocks|
    mocks.verify_doubled_constant_names = true
  end
end

def project_path
  File.expand_path('../..', __FILE__)
end

def fixture(fixture_name)
  Pathname.new(project_path + '/spec/fixtures/digitalocean/').join("#{fixture_name}.json").read
end
