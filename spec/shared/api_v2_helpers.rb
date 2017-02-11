# -*- encoding : utf-8 -*-
require 'spec_helper'

RSpec.shared_context 'api_v2_helpers' do
  let(:api_base)             { 'https://api.digitalocean.com/v2' }
  let(:droplets_api_base)    { "#{api_base}/droplets" }
  let(:api_access_token)     { "Bearer #{access_token}" }
  let(:events_api_base)      { "#{api_base}/droplets/[droplet_id]/actions" }
  let(:actions_api_base)     { "#{api_base}/actions" }
  let(:images_api_base)      { "#{api_base}/images" }
  let(:image_destroy_uri)    { "#{images_api_base}/[id]" }
  let(:droplets_uri)         { "#{droplets_api_base}?per_page=200" }
  let(:droplet_find_uri)     { "#{droplets_api_base}/[id]?per_page=200" }
  let(:droplet_stop_uri)     { "#{droplets_api_base}/[id]/actions" }
  let(:droplet_start_uri)    { "#{droplets_api_base}/[id]/actions" }
  let(:droplet_snapshot_uri) { "#{droplets_api_base}/[id]/actions" }
  let(:event_find_uri)       { "#{events_api_base}/[id]" }
  let(:action_find_uri)      { "#{actions_api_base}/[id]?per_page=200" }
  let(:volumes_api_base)     { "#{api_base}/volumes" }
  let(:volumes_uri)          { "#{volumes_api_base}?per_page=200" }
  let(:volume_find_uri)      { "#{volumes_api_base}/[id]?per_page=200" }
  let(:volume_snapshot_uri)  { "#{volumes_api_base}/[id]/snapshots" }
  let(:snapshots_api_base)   { "#{api_base}/snapshots" }
  let(:snapshot_destroy_uri) { "#{snapshots_api_base}/[id]" }
  def snapshots_uri(resource_type)
    "#{api_base}/snapshots?per_page=200&resource_type=#{resource_type}"
  end

  # List of droplets
  #
  def stub_droplets
    stub_without_id(droplets_uri, 'v2/show_droplets')
  end

  def stub_droplets_empty
    stub_without_id(droplets_uri, 'v2/show_droplets_empty')
  end

  def stub_droplets_fail
    stub_without_id(droplets_uri, 'v2/error_message')
  end

  # Droplet data
  #
  def stub_droplet(id)
    stub_with_id(droplet_find_uri, id, 'v2/show_droplet')
  end

  def stub_droplet_fail(id)
    stub_with_id(droplet_find_uri, id, 'v2/error_message')
  end

  def stub_droplet_inactive(id)
    stub_with_id(droplet_find_uri, id, 'v2/show_droplet_inactive')
  end

  # Droplet actions
  #
  def stub_droplet_stop(id)
    stub_with_id(droplet_stop_uri, id, 'v2/show_event_power_off_start', :post,
                 type: 'power_off'
                )
  end

  def stub_droplet_stop_fail(id)
    stub_with_id(droplet_stop_uri, id, 'v2/error_message', :post,
                 {
                   type: 'power_off'
                 },
                 404
                )
  end

  def stub_droplet_start(id)
    stub_with_id(droplet_start_uri, id, 'v2/show_event_power_on_start', :post,
                 type: 'power_on'
                )
  end

  def stub_droplet_start_done(id)
    stub_with_id(droplet_start_uri, id, 'v2/show_event_power_on_done', :post,
                 type: 'power_on'
                )
  end

  def stub_droplet_start_fail(id)
    stub_with_id(droplet_start_uri, id, 'v2/error_message', :post,
                 type: 'power_on'
                )
  end

  # Droplet Snapshot
  #
  def stub_droplet_snapshot(id, name)
    stub_with_id_name(droplet_snapshot_uri, id, name, 'v2/response_event', :post,
                      type: 'snapshot',
                      name: name
                     )
  end

  def stub_droplet_snapshot_fail(id, name)
    stub_with_id_name(droplet_snapshot_uri, id, name, 'v2/error_message', :post,
                      {
                        type: 'snapshot',
                        name: name
                      },
                      404
                     )
  end

  # Event status
  #
  def stub_event_done(id)
    stub_with_id(action_find_uri, id, 'v2/show_event_done')
  end

  def stub_event_fail(id)
    stub_with_id(action_find_uri, id, 'v2/error_message')
  end

  def stub_event_running(id)
    stub_with_id(action_find_uri, id, 'v2/show_event_start')
  end

  # Image actions
  #
  def stub_image_destroy(id)
    stub_with_id(image_destroy_uri, id, 'v2/empty', :delete, nil, 204)
  end

  def stub_image_destroy_fail(id)
    stub_with_id(image_destroy_uri, id, 'v2/error_message', :delete, nil, 404)
  end

  # List of volumes
  #
  def stub_volumes
    stub_without_id(volumes_uri, 'v2/show_volumes')
  end

  def stub_volumes_empty
    stub_without_id(volumes_uri, 'v2/show_volumes_empty')
  end

  def stub_volumes_fail
    stub_without_id(volumes_uri, 'v2/error_message')
  end

  # Volume data
  #
  def stub_volume(id)
    stub_with_id(volume_find_uri, id, 'v2/show_volume')
  end

  def stub_volume_fail(id)
    stub_with_id(volume_find_uri, id, 'v2/error_message')
  end

  # Volume Snapshot
  #
  def stub_volume_snapshots(id)
    stub_with_id(volume_snapshot_uri, id, 'v2/response_snapshot')
  end

  def stub_volume_snapshot(id, name)
    stub_with_id_name(volume_snapshot_uri, id, name, 'v2/response_snapshot', :post,
                      name: name
                     )
  end

  def stub_volume_snapshot_fail(id, name)
    stub_with_id_name(volume_snapshot_uri, id, name, 'v2/error_message', :post,
                      {
                        name: name
                      },
                      404
                     )
  end


  # List of snapshots
  #
  def stub_snapshots(resource_type)
    stub_without_id(snapshots_uri(resource_type), 'v2/show_snapshots')
  end

  def stub_snapshots_empty(resource_type)
    stub_without_id(snapshots_uri(resource_type), 'v2/show_snapshots_empty')
  end

  def stub_snapshots_fail(resource_type)
    stub_without_id(snapshots_uri(resource_type), 'v2/error_message')
  end

  # Snapshot data
  #
  def stub_snapshot(id)
    stub_with_id(snapshot_find_uri, id, 'v2/show_snapshot')
  end

  def stub_snapshot_fail(id)
    stub_with_id(snapshot_find_uri, id, 'v2/error_message')
  end

  # Snapshot actions
  #
  def stub_snapshot_destroy(id)
    stub_with_id(snapshot_destroy_uri, id, 'v2/empty', :delete, nil, 204)
  end

  def stub_snapshot_destroy_fail(id)
    stub_with_id(snapshot_destroy_uri, id, 'v2/error_message', :delete, nil, 404)
  end

  # Stub helpers
  #
  def stub_with_id(request, id, fixture, type = :get, body = nil, status = 200) # rubocop:disable Metrics/ParameterLists
    return unless request && fixture && id
    stub_request_body(type, url_with_id(request, id), body)
      .to_return(status: status, body: fixture(fixture))
  end

  def stub_without_id(request, fixture, type = :get, body = nil, status = 200)
    return unless request && fixture
    stub_request_body(type, request, body)
      .to_return(status: status, body: fixture(fixture))
  end

  def stub_with_id_name(request, id, name, fixture, type = :get, body = nil, status = 200) # rubocop:disable Metrics/ParameterLists
    return unless request && fixture && id && name
    stub_request_body(type, url_with_id_name(request, id, name), body)
      .to_return(status: status, body: fixture(fixture))
  end

  # Body Helpers
  #
  def stub_request_body(type, request, body)
    stub_response = stub_request(type, request).with(headers: { 'Authorization' => api_access_token })
    return stub_response.with(body: body) if body
    stub_response
  end
end
