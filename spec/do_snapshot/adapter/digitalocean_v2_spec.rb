# -*- encoding : utf-8 -*-
require 'spec_helper'

RSpec.describe DoSnapshot::Adapter::DigitaloceanV2 do
  include_context 'environment'
  include_context 'api_v2_helpers'

  subject(:api) { described_class }
  subject(:log) { DoSnapshot::Log }

  describe '.initialize' do
    describe '#delay' do
      let(:delay) { 5 }
      let(:instance) { api.new(delay: delay) }
      it('with custom delay') { expect(instance.delay).to eq delay }
    end

    describe '#timeout' do
      let(:timeout) { 5 }
      let(:instance) { api.new(timeout: timeout) }
      it('with custom timeout') { expect(instance.timeout).to eq timeout }
    end
  end

  describe 'droplets' do
    let(:instance) { api.new(delay: delay, timeout: timeout) }
    include_context 'uri_helpers'

    describe '.droplet' do
      it 'with droplet' do
        stub_droplet(droplet_id)

        instance.droplet(droplet_id)

        expect(a_request(:get, droplet_url))
          .to have_been_made
      end

      it 'with error' do
        stub_droplet_fail(droplet_id)

        expect { instance.droplet(droplet_id) }
          .to raise_error(DoSnapshot::DropletFindError)
        expect(DoSnapshot.logger.buffer)
          .to include "Droplet id: #{droplet_id} Not Found"

        expect(a_request(:get, droplet_url))
          .to have_been_made
      end
    end

    describe '.droplets' do
      it 'with droplets' do
        stub_droplets

        instance.droplets

        expect(a_request(:get, droplets_uri))
          .to have_been_made
      end

      it 'with error' do
        stub_droplets_fail

        # expect { instance.droplets }.to raise_error(DoSnapshot::DropletListError)
        expect(instance.droplets.collection).to eq([])
        # expect(DoSnapshot.logger.buffer)
        #   .to include 'Droplet Listing is failed to retrieve'

        expect(a_request(:get, droplets_uri))
          .to have_been_made
      end
    end

    describe '.start_droplet' do
      it 'with event' do
        stub_droplet_inactive(droplet_id)
        stub_droplet_start(droplet_id)

        instance.start_droplet(droplet_id)
        expect(DoSnapshot.logger.buffer).to include "Droplet id: #{droplet_id} is requested for Power On."

        expect(a_request(:post, droplet_start_url))
          .to have_been_made
        expect(a_request(:get, droplet_url))
          .to have_been_made
      end

      it 'with warning message' do
        stub_droplet(droplet_id)

        expect { instance.start_droplet(droplet_id) }
          .not_to raise_error
        expect(DoSnapshot.logger.buffer)
          .to include "Droplet #{droplet_id} is still running. Skipping."

        expect(a_request(:get, droplet_url))
          .to have_been_made
      end

      it 'with error' do
        stub_droplet_fail(droplet_id)

        expect { instance.start_droplet(droplet_id) }
          .to raise_error(DoSnapshot::DropletFindError)

        expect(a_request(:get, droplet_url))
          .to have_been_made
      end
    end

    describe '.stop_droplet by power status' do
      let(:instance) { api.new(delay: delay, timeout: timeout, stop_by: :power_status) }

      it 'with success' do
        stub_event_done(event_id)
        stub_droplet_stop(droplet_id)
        stub_droplet_inactive(droplet_id)

        instance.stop_droplet(droplet_id)

        expect(a_request(:post, droplet_stop_url))
          .to have_been_made
        expect(a_request(:get, droplet_url))
          .to have_been_made
      end

      it 'with error' do
        stub_droplet_stop_fail(droplet_id)
        stub_droplet(droplet_id)
        instance.timeout = 1
        expect { instance.stop_droplet(droplet_id) }
          .to raise_error(DoSnapshot::DropletShutdownError)
        instance.timeout = timeout
        expect(DoSnapshot.logger.buffer)
          .to include 'Droplet id: 100823 is Failed to Power Off.'

        expect(a_request(:post, droplet_stop_url))
          .to have_been_made
      end
    end

    describe '.stop_droplet by event' do
      it 'with success' do
        stub_event_done(event_id)
        stub_droplet_stop(droplet_id)

        instance.stop_droplet(droplet_id)

        expect(a_request(:post, droplet_stop_url))
          .to have_been_made
        expect(a_request(:get, action_find_url))
          .to have_been_made
      end

      it 'with error' do
        stub_droplet_stop_fail(droplet_id)

        expect { instance.stop_droplet(droplet_id) }
          .to raise_error(DoSnapshot::DropletShutdownError)
        expect(DoSnapshot.logger.buffer)
          .to include 'Droplet id: 100823 is Failed to Power Off.'

        expect(a_request(:post, droplet_stop_url))
          .to have_been_made
      end
    end

    describe '.create_snapshot' do
      it 'with success' do
        stub_event_done(event_id)
        stub_droplet_snapshot(droplet_id, snapshot_name)

        expect { instance.create_snapshot(droplet_id, snapshot_name) }
          .not_to raise_error

        expect(a_request(:post, droplet_snapshot_url))
          .to have_been_made
        expect(a_request(:get, action_find_url))
          .to have_been_made
      end

      it 'with error' do
        stub_droplet_snapshot_fail(droplet_id, snapshot_name)

        expect { instance.create_snapshot(droplet_id, snapshot_name) }
          .to raise_error(DoSnapshot::SnapshotCreateError)

        expect(a_request(:post, droplet_snapshot_url))
          .to have_been_made
      end

      it 'with event error' do
        stub_droplet_snapshot(droplet_id, snapshot_name)
        stub_event_fail(event_id)

        expect { instance.create_snapshot(droplet_id, snapshot_name) }
          .not_to raise_error
        expect(DoSnapshot.logger.buffer)
          .to include "Event id: #{event_id} is failed!"

        expect(a_request(:post, droplet_snapshot_url))
          .to have_been_made
        expect(a_request(:get, action_find_url))
          .to have_been_made
      end
    end

    describe '.inactive?' do
      it 'when inactive' do
        stub_droplet_inactive(droplet_id)

        expect(instance.inactive?(droplet_id))
          .to be_truthy
      end

      it 'when active' do
        stub_droplet(droplet_id)

        expect(instance.inactive?(droplet_id))
          .to be_falsey
      end
    end

    describe '.cleanup_snapshots' do
      it 'with success' do
        stub_droplet(droplet_id)
        stub_image_destroy(image_id)
        stub_image_destroy(image_id2)

        droplet = instance.droplet(droplet_id)
        expect { instance.cleanup_snapshots(droplet, 1) }
          .not_to raise_error
        expect(DoSnapshot.logger.buffer)
          .to include 'Snapshot: 5019770 delete requested.'

        expect(a_request(:get, droplet_url))
          .to have_been_made
        expect(a_request(:delete, image_destroy_url))
          .to have_been_made
        expect(a_request(:delete, image_destroy2_url))
          .to have_been_made
      end

      it 'with warning message' do
        stub_droplet(droplet_id)
        stub_image_destroy_fail(image_id)
        stub_image_destroy_fail(image_id2)

        droplet = instance.droplet(droplet_id)
        expect { instance.cleanup_snapshots(droplet, 1) }
            .not_to raise_error
        expect(DoSnapshot.logger.buffer)
            .to include 'Destroy of snapshot 5019903 for droplet id: 100823 name: example.com is failed.'

        expect(a_request(:get, droplet_url))
            .to have_been_made
        expect(a_request(:delete, image_destroy_url))
            .to have_been_made
        expect(a_request(:delete, image_destroy2_url))
            .to have_been_made
      end
    end
  end
end
