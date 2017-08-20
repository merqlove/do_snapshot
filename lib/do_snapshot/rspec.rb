# frozen_string_literal: true
require 'rspec/core/shared_context'

module DoSnapshot
  module RSpec # rubocop:disable Style/Documentation
    autoload :Adapter, 'do_snapshot/rspec/adapter'
    autoload :ApiHelpers, 'do_snapshot/rspec/api_helpers'
    autoload :ApiV2Helpers, 'do_snapshot/rspec/api_v2_helpers'
    autoload :Environment, 'do_snapshot/rspec/environment'
    autoload :UriHelpers, 'do_snapshot/rspec/uri_helpers'
  end
end
