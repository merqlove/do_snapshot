# -*- encoding : utf-8 -*-
require 'spec_helper'

RSpec.shared_context 'uri_helpers' do
  let(:droplet_url) { url_with_id(droplet_find_uri, droplet_id) }
  let(:droplet_stop_url) { url_with_id(droplet_stop_uri, droplet_id) }
  let(:droplet_start_url) { url_with_id(droplet_start_uri, droplet_id) }
  let(:event_find_url) { url_with_id(event_find_uri, event_id) }
  let(:image_destroy_url) { url_with_id(image_destroy_uri, image_id) }
  let(:image_destroy2_url) { url_with_id(image_destroy_uri, image_id2) }
  let(:action_find_url) { url_with_id(action_find_uri, event_id) }
  let(:droplet_snapshot_url) { url_with_id_name(droplet_snapshot_uri, droplet_id, snapshot_name) }
  let(:volume_url) { url_with_id(volume_find_uri, volume_id) }
  let(:volume_snapshot_url) { url_with_id_name(volume_snapshot_uri, volume_id, snapshot_name) }
  let(:snapshot_destroy_url) { url_with_id(snapshot_destroy_uri, snapshot_id) }
  let(:snapshot_destroy2_url) { url_with_id(snapshot_destroy_uri, snapshot_id2) }
  let(:snapshot_destroy3_url) { url_with_id(snapshot_destroy_uri, snapshot_id3) }
end
