# -*- encoding : utf-8 -*-
# frozen_string_literal: true
require 'bundler'
Bundler.setup

require 'webmock/rspec'
require 'new_adapter'
require 'do_snapshot/cli'
require 'do_snapshot/rspec'

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
  DoSnapshot::RSpec.project_path
end

def fixture(fixture_name)
  DoSnapshot::RSpec.fixture(fixture_name)
end
