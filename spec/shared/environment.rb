# -*- encoding : utf-8 -*-
require 'spec_helper'

RSpec.shared_context 'environment' do
  include_context 'api_helpers'

  def do_not_send_email
    allow(Pony).to receive(:deliver) { |mail| mail }
  end

  let(:client_key)           { 'foo' }
  let(:api_key)              { 'bar' }
  let(:access_token)         { 'sometoken' }
  let(:event_id)             { '7499' }
  let(:droplet_id)           { '100823' }
  let(:volume_id)            { '7724db7c-e098-11e5-b522-000f53304e51' }
  let(:image_id)             { '5019770' }
  let(:image_id2)            { '5019903' }
  let(:snapshot_id)          { '5019770' }
  let(:snapshot_id2)         { '5019903' }
  let(:snapshot_id3)         { '119192817' }
  let(:cli_env_nil)          { Hash['DIGITAL_OCEAN_CLIENT_ID' => nil, 'DIGITAL_OCEAN_API_KEY' => nil, 'DIGITAL_OCEAN_ACCESS_TOKEN' => nil] }
  let(:cli_keys)             { Thor::CoreExt::HashWithIndifferentAccess.new(digital_ocean_access_token: access_token) }
  let(:cli_keys_other)       { Thor::CoreExt::HashWithIndifferentAccess.new(digital_ocean_access_token: 'NOTTOK') }
  let(:snapshot_name)        { "example.com_#{DateTime.now.strftime('%Y-%m-%d-%H-%M')}" }
  let(:volume_snapshot_name) { "Example_#{DateTime.now.strftime('%Y-%m-%d-%H-%M')}" }
  let(:default_options)      { Hash[protocol: 2, resource_types: 'droplets', only: %w( 100823 ), exclude: %w(), keep: 3, stop: false, trace: true, clean: true, delay: 0, shutdown: true, timeout: 600] }
  let(:default_options_cli)  { default_options.reject { |key, _| %w( droplets threads ).include?(key.to_s) } }
  let(:no_exclude)           { [] }
  let(:exclude)              { %w( 100824 100825 ) }
  let(:no_only)              { [] }
  let(:only)                 { %w( 100823 100824 ) }
  let(:stop)                 { true }
  let(:no_stop)              { false }
  let(:quiet)                { true }
  let(:no_quiet)             { false }
  let(:clean)                { true }
  let(:no_clean)             { false }
  let(:shutdown)             { true }
  let(:timeout)              { 600 }
  let(:delay)                { 0 }
  let(:log_path)             { "#{project_path}/log/test.log" }
  let(:mail_options)         { Thor::CoreExt::HashWithIndifferentAccess.new(to: 'mail@somehost.com', from: 'from@host.com') }
  let(:smtp_options)         { Thor::CoreExt::HashWithIndifferentAccess.new(address: 'smtp.gmail.com', port: '25', user_name: 'someuser', password: 'somepassword') }
  let(:log)                  { Thor::CoreExt::HashWithIndifferentAccess.new(log: log_path) }

  def stub_all_api(droplets = nil, active = false)
    drops = []
    droplets ||= [droplet_id]
    droplets.each do |droplet|
      drops.push Hash[
        stub_droplet: (active ? stub_droplet(droplet) : stub_droplet_inactive(droplet))
      ].merge(stub_droplet_api(droplet))
    end
    volumes ||= [volume_id]
    volumes.each do |volume|
      drops.push Hash[
        stub_volume: stub_volume(volume)
      ].merge(stub_volume_api(volume))
    end

    stubs = Hash[drops: drops]
    @stubs = stubs.merge(default_stub_api)
  end

  def stub_droplet_api(droplet)
    {
      stub_droplet_stop: stub_droplet_stop(droplet),
      stub_droplet_start: stub_droplet_start(droplet),
      stub_droplet_snapshot: stub_droplet_snapshot(droplet, snapshot_name)
    }
  end

  def stub_volume_api(volume)
    {
      stub_volume_find_snapshots: stub_snapshots('volume'),
      stub_volume_snapshots: stub_volume_snapshots(volume),
      stub_volume_snapshot: stub_volume_snapshot(volume, volume_snapshot_name)
    }
  end

  def default_stub_api
    {
      stub_event_done: stub_event_done(event_id),
      stub_droplets: stub_droplets,
      stub_volumes: stub_volumes,
      stub_snapshot_destroy1: stub_snapshot_destroy(snapshot_id),
      stub_snapshot_destroy2: stub_snapshot_destroy(snapshot_id2),
      stub_snapshot_destroy3: stub_snapshot_destroy(snapshot_id3)
    }
  end

  def stub_cleanup
    @stubs ||= {}
    @stubs.each_pair do |_k, v|
      remove_request_stub(v) if v.class == WebMock::RequestStub
      next unless v.class == Array

      v.each do |d|
        d.each_pair do |_dk, dv|
          remove_request_stub(dv) if v.class == WebMock::RequestStub
        end
      end
    end
  end

  def reset_api_keys
    ENV['DIGITAL_OCEAN_API_KEY']   = nil
    ENV['DIGITAL_OCEAN_CLIENT_ID'] = nil
    ENV['DIGITAL_OCEAN_ACCESS_TOKEN'] = nil
  end

  def set_api_keys
    ENV['DIGITAL_OCEAN_API_KEY']   = api_key
    ENV['DIGITAL_OCEAN_CLIENT_ID'] = client_key
    ENV['DIGITAL_OCEAN_ACCESS_TOKEN'] = access_token
  end

  def reset_singletons
    DoSnapshot.configure do |config|
      # config.logger = Logger.new($stdout)
      config.verbose = false
      config.quiet = true
    end
    DoSnapshot.logger = DoSnapshot::Log.new
    DoSnapshot.mailer = DoSnapshot.config.mailer
  end

  before(:all) do
    WebMock.reset!
  end

  before(:each) do
    do_not_send_email
    set_api_keys
    reset_singletons
  end
end
