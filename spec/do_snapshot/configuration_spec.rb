# frozen_string_literal: true
require 'spec_helper'

RSpec.describe DoSnapshot::Configuration do
  subject(:cli) { described_class }

  it { expect(cli.new).to respond_to(:logger) }
  it { expect(cli.new).to respond_to(:logger_level) }
  it { expect(cli.new).to respond_to(:verbose) }
  it { expect(cli.new).to respond_to(:quiet) }
  it { expect(cli.new).to respond_to(:mailer) }
end
