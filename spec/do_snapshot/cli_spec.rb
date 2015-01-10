# -*- encoding : utf-8 -*-
require 'spec_helper'

describe DoSnapshot::CLI do
  include_context 'spec'

  subject(:cli)     { described_class }
  subject(:command) { DoSnapshot::Command }
  subject(:api)     { DoSnapshot::API }

  describe '.snap' do
    it 'with exclude' do
      excluded_droplets = %w( 100824 )
      stub_all_api(%w(100825 100823))
      hash_attribute_eq_no_stub(exclude: excluded_droplets, only: %w())

      expect(command.send('exclude'))
        .to eq excluded_droplets
    end

    it 'with only' do
      selected_droplets = %w( 100823 )
      stub_all_api(selected_droplets)
      hash_attribute_eq_no_stub(only: selected_droplets)

      expect(command.send('only'))
        .to eq selected_droplets
    end

    it 'with 1 delay' do
      set_api_attribute(delay: 1, timeout: timeout)
      attribute_eq 'delay', 1
    end

    it 'with 0 delay' do
      set_api_attribute(delay: 0, timeout: timeout)
      attribute_eq 'delay', 0
    end

    it 'with custom timeout' do
      set_api_attribute(timeout: 1, delay: delay)
      attribute_eq 'timeout', 1
    end

    it 'with keep' do
      attribute_eq 'keep', 7
    end

    it 'with quiet' do
      attribute_eq 'quiet', true
    end

    it 'with no quiet' do
      attribute_eq 'quiet', false
    end

    it 'with stop' do
      attribute_eq 'stop', true
    end

    it 'with no stop' do
      attribute_eq 'stop', false
    end

    it 'with clean' do
      attribute_eq 'clean', true
    end

    it 'with no clean' do
      attribute_eq 'clean', false
    end

    it 'with digital ocean credentials' do
      with_hash_attribute_eq(cli_keys)
    end

    it 'with no digital ocean credentials' do
      without_hash_attribute_eq(cli_keys)
    end

    it 'with mail' do
      hash_attribute_eq(mail_options)
    end

    it 'with no mail' do
      without_hash_attribute_eq(mail_options)
    end

    it 'with smtp' do
      hash_attribute_eq(smtp_options)
    end

    it 'with no smtp' do
      without_hash_attribute_eq(smtp_options)
    end

    it 'with log' do
      hash_attribute_eq(log)
    end

    it 'with no log' do
      without_hash_attribute_eq(log)
    end
  end

  describe '.version' do
    it 'shows the correct version' do
      @cli.options = @cli.options.merge(version: true)
      @cli.version

      expect($stdout.string.chomp)
        .to eq("#{DoSnapshot::VERSION}")
    end
  end

  describe '.help' do
    it 'shows a help message' do
      @cli.help
      expect($stdout.string)
        .to match('Commands:')
    end

    it 'shows a help message for specific commands' do
      @cli.help 'snap'
      expect($stdout.string)
        .to match('Usage:')
    end
  end

  def attribute_eq(name, value)
    stub_all_api
    options = default_options.merge!(:"#{name}" => value)
    @cli.options = @cli.options.merge(options)
    @cli.snap

    expect(command.send(name))
      .to eq value
  end

  def hash_attribute_eq(hash)
    stub_all_api
    options = default_options.merge!(hash)
    @cli.options = @cli.options.merge(options)
    @cli.snap
  end

  def with_hash_attribute_eq(hash)
    hash_attribute_eq hash
    expect(@cli.options)
      .to include(hash)
  end

  def without_hash_attribute_eq(hash)
    hash_attribute_eq({})
    expect(@cli.options)
      .not_to include(hash)
  end

  def hash_attribute_eq_no_stub(hash)
    options = default_options.merge!(hash)
    @cli.options = @cli.options.merge(options)
    @cli.snap
  end

  def set_api_attribute(options = { delay: delay, timeout: timeout }) # rubocop:disable Style/AccessorMethodName
    command.send('api=', api.new(options))
  end

  before(:each) do
    $stdout.sync = true
    $stderr.sync = true

    @cli = cli.new

    # Keep track of the old stderr / out
    @orig_stderr = $stderr
    @orig_stdout = $stdout

    # Make them strings so we can manipulate and compare.
    $stderr = StringIO.new
    $stdout = StringIO.new
  end

  after(:each) do
    # Reassign the stderr / out so rspec can have it back.
    $stderr = @orig_stderr
    $stdout = @orig_stdout
  end
end
