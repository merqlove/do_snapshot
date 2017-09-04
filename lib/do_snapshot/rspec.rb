# frozen_string_literal: true
require 'rspec/core/shared_context'

module DoSnapshot
  module RSpec # rubocop:disable Style/Documentation
    autoload :Adapter, 'do_snapshot/rspec/adapter'
    autoload :ApiHelpers, 'do_snapshot/rspec/api_helpers'
    autoload :ApiV2Helpers, 'do_snapshot/rspec/api_v2_helpers'
    autoload :Environment, 'do_snapshot/rspec/environment'
    autoload :UriHelpers, 'do_snapshot/rspec/uri_helpers'

    def self.project_path
      File.expand_path('../../..', __FILE__)
    end

    def self.fixture(fixture_name)
      Pathname.new(project_path + '/lib/do_snapshot/rspec/fixtures/digitalocean/').join("#{fixture_name}.json").read
    end
  end
end
