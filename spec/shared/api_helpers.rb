# -*- encoding : utf-8 -*-
require 'spec_helper'

shared_context 'api_helpers' do

  # List of droplets
  #
  def stub_droplets
    stub_without_id(droplets_uri, 'show_droplets')
  end

  def stub_droplets_empty
    stub_without_id(droplets_uri, 'show_droplets_empty')
  end

  def stub_droplets_fail
    stub_without_id(droplets_uri, 'error_message')
  end

  # Droplet data
  #
  def stub_droplet(id)
    stub_with_id(droplet_find_uri, id, 'show_droplet')
  end

  def stub_droplet_fail(id)
    stub_with_id(droplet_find_uri, id, 'error_message')
  end

  def stub_droplet_inactive(id)
    stub_with_id(droplet_find_uri, id, 'show_droplet_inactive')
  end

  # Droplet actions
  #
  def stub_droplet_stop(id)
    stub_with_id(droplet_stop_uri, id, 'response_event')
  end

  def stub_droplet_stop_fail(id)
    stub_with_id(droplet_stop_uri, id, 'error_message')
  end

  def stub_droplet_start(id)
    stub_with_id(droplet_start_uri, id, 'response_event')
  end

  def stub_droplet_start_fail(id)
    stub_with_id(droplet_start_uri, id, 'error_message')
  end

  # Snapshot
  #
  def stub_droplet_snapshot(id, name)
    stub_with_id_name(snapshot_uri, id, name, 'response_event')
  end

  def stub_droplet_snapshot_fail(id, name)
    stub_with_id_name(snapshot_uri, id, name, 'error_message')
  end

  # Event status
  #
  def stub_event_done(id)
    stub_with_id(event_find_uri, id, 'show_event_done')
  end

  def stub_event_fail(id)
    stub_with_id(event_find_uri, id, 'error_message')
  end

  def stub_event_running(id)
    stub_with_id(event_find_uri, id, 'show_event_running')
  end

  # Image actions
  #
  def stub_image_destroy(id)
    stub_with_id(image_destroy_uri, id, 'response_event')
  end

  def stub_image_destroy_fail(id)
    stub_with_id(image_destroy_uri, id, 'error_message')
  end

  # Stub helpers
  #
  def stub_with_id(request, id, fixture, status = 200)
    return unless request && fixture && id
    stub_request(:get, url_with_id(request, id))
      .to_return(status: status, body: fixture(fixture))
  end

  def stub_without_id(request, fixture, status = 200)
    return unless request && fixture
    stub_request(:get, request)
      .to_return(status: status, body: fixture(fixture))
  end

  def stub_with_id_name(request, id, name, fixture, status = 200)
    return unless request && fixture && id && name
    stub_request(:get, url_with_id_name(request, id, name))
      .to_return(status: status, body: fixture(fixture))
  end

  # Url helpers
  #
  def url_with_id(request, id)
    return unless request && id
    request.sub('[id]', id.to_s)
  end

  def url_with_id_name(request, id, name)
    return unless request && id && name
    request.sub('[id]', id.to_s).sub('[name]', name)
  end
end
