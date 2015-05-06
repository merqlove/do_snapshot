# -*- encoding : utf-8 -*-
require 'spec_helper'

shared_context 'api_v1_helpers' do
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

  # List of droplets
  #
  def stub_droplets
    stub_without_id(droplets_uri, 'v1/show_droplets')
  end

  def stub_droplets_empty
    stub_without_id(droplets_uri, 'v1/show_droplets_empty')
  end

  def stub_droplets_fail
    stub_without_id(droplets_uri, 'v1/error_message')
  end

  # Droplet data
  #
  def stub_droplet(id)
    stub_with_id(droplet_find_uri, id, 'v1/show_droplet')
  end

  def stub_droplet_fail(id)
    stub_with_id(droplet_find_uri, id, 'v1/error_message')
  end

  def stub_droplet_inactive(id)
    stub_with_id(droplet_find_uri, id, 'v1/show_droplet_inactive')
  end

  # Droplet actions
  #
  def stub_droplet_stop(id)
    stub_with_id(droplet_stop_uri, id, 'v1/response_event')
  end

  def stub_droplet_stop_fail(id)
    stub_with_id(droplet_stop_uri, id, 'v1/error_message')
  end

  def stub_droplet_start(id)
    stub_with_id(droplet_start_uri, id, 'v1/response_event')
  end

  def stub_droplet_start_fail(id)
    stub_with_id(droplet_start_uri, id, 'v1/error_message')
  end

  # Snapshot
  #
  def stub_droplet_snapshot(id, name)
    stub_with_id_name(snapshot_uri, id, name, 'v1/response_event')
  end

  def stub_droplet_snapshot_fail(id, name)
    stub_with_id_name(snapshot_uri, id, name, 'v1/error_message')
  end

  # Event status
  #
  def stub_event_done(id)
    stub_with_id(event_find_uri, id, 'v1/show_event_done')
  end

  def stub_event_fail(id)
    stub_with_id(event_find_uri, id, 'v1/error_message')
  end

  def stub_event_running(id)
    stub_with_id(event_find_uri, id, 'v1/show_event_running')
  end

  # Image actions
  #
  def stub_image_destroy(id)
    stub_with_id(image_destroy_uri, id, 'v1/response_event')
  end

  def stub_image_destroy_fail(id)
    stub_with_id(image_destroy_uri, id, 'v1/error_message')
  end
end
