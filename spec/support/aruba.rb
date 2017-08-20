# frozen_string_literal: true
require 'aruba/rspec'
require 'do_snapshot/runner'

Aruba.configure do |config|
  config.command_launcher = :in_process
  config.main_class = DoSnapshot::Runner
end
