# frozen_string_literal: true
require 'do_snapshot/helpers'
require 'do_snapshot/adapter'

module NewAdapter
  class Adapter < ::DoSnapshot::Adapter::DropletKit
  end
end
