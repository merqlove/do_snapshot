require 'spec_helper'

shared_context 'spec' do
  include_context 'api_helpers'

  let(:client_key)         { 'foo' }
  let(:api_key)            { 'bar' }
  let(:event_id)           { '7501' }
  let(:droplet_id)         { '100823' }
  let(:image_id)           { '5019770' }
  let(:image_id2)          { '5019903' }
  let(:cli_keys)           { Thor::CoreExt::HashWithIndifferentAccess.new(digital_ocean_client_id: 'NOTFOO', digital_ocean_client_bar: 'NOTBAR') }
  let(:snapshot_name)      { "foo_#{DateTime.now.strftime('%Y_%m_%d')}" }
  let(:default_options)    { Hash[only: %w( 100823 ), exclude: %w(), keep: 3, trace: true, clean: true, delay: 0, timeout: 180] }
  let(:no_exclude)         { [] }
  let(:exclude)            { %w( 100824 100825 ) }
  let(:no_only)            { [] }
  let(:only)               { %w( 100823 100824 ) }
  let(:stop)               { true }
  let(:no_stop)            { false }
  let(:quiet)              { true }
  let(:no_quiet)           { false }
  let(:clean)              { true }
  let(:no_clean)           { false }
  let(:timeout)            { 180 }
  let(:delay)              { 0 }
  let(:mail_options)       { Thor::CoreExt::HashWithIndifferentAccess.new(to: 'mail@somehost.com', from: 'from@host.com') }
  let(:smtp_options)       { Thor::CoreExt::HashWithIndifferentAccess.new(address: 'smtp.gmail.com', port: '25', user_name: 'someuser', password: 'somepassword') }
  let(:log)                { Thor::CoreExt::HashWithIndifferentAccess.new(log: "#{project_path}/log/test.log") }
  let(:api_base)           { 'https://api.digitalocean.com/v1' }
  let(:keys_uri)           { "api_key=#{api_key}&client_id=#{client_key}" }
  let(:droplets_api_base)  { "#{api_base}/droplets" }
  let(:events_api_base)    { "#{api_base}/events" }
  let(:images_api_base)    { "#{api_base}/images" }
  let(:image_destroy_uri)  { "#{images_api_base}/[id]/destroy/?#{keys_uri}" }
  let(:droplets_uri)       { "#{droplets_api_base}/?#{keys_uri}" }
  let(:droplet_find_uri)   { "#{droplets_api_base}/[id]?#{keys_uri}" }
  let(:droplet_stop_uri)   { "#{droplets_api_base}/[id]/power_off/?#{keys_uri}" }
  let(:droplet_start_uri)  { "#{droplets_api_base}/[id]/power_on/?#{keys_uri}" }
  let(:snapshot_uri)       { "#{droplets_api_base}/[id]/snapshot/?name=[name]&#{keys_uri}" }
  let(:event_find_uri)     { "#{events_api_base}/[id]/?#{keys_uri}" }

  before(:each) do
    $stdout.sync = true
    $stderr.sync = true

    ENV['DIGITAL_OCEAN_API_KEY']   = api_key
    ENV['DIGITAL_OCEAN_CLIENT_ID'] = client_key

    @cli = DoSnapshot::CLI.new

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

  def stub_all_api(droplets = nil, active = false) # rubocop:disable MethodLength
    drops = []
    droplets ||= [droplet_id]
    droplets.each do |droplet|
      drops.push Hash[
        stub_droplet: (active ? stub_droplet(droplet) : stub_droplet_inactive(droplet))
      ].merge(stub_droplet_api(droplet))
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

  def default_stub_api
    {
      stub_event_done: stub_event_done(event_id),
      stub_droplets: stub_droplets,
      stub_image_destroy1: stub_image_destroy(image_id),
      stub_image_destroy2: stub_image_destroy(image_id2)
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

  before(:all) do
    WebMock.reset!
  end
end
