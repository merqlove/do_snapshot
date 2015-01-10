# -*- encoding : utf-8 -*-
require 'spec_helper'

describe DoSnapshot::Command do
  include_context 'spec'
  include_context 'uri_helpers'

  subject(:cmd)     { DoSnapshot::Command }
  subject(:log)     { DoSnapshot::Log }

  describe '.snap' do
    context 'when success' do
      it 'sends message' do
        expect { snap_runner }
          .not_to raise_error
        expect(log.buffer)
          .to include 'All operations has been finished.'
      end
    end

    context 'when snapshot not cleanup' do
      it 'sends message' do
        stub_image_destroy_fail(image_id)
        stub_image_destroy_fail(image_id2)

        expect { snap_runner }
          .not_to raise_error
      end
    end

    context 'when droplet not found' do
      it 'raised by exception' do
        stub_droplet_fail(droplet_id)

        expect { snap_runner }
          .to raise_error(DoSnapshot::DropletFindError)
      end
    end

    context 'when failed to list droplets' do
      it 'raised with error' do
        stub_droplets_fail

        expect { snap_runner }
          .to raise_error(DoSnapshot::DropletListError)
      end
    end

    context 'when droplet failed for shutdown' do
      it 'raised with error' do
        stub_droplet_stop_fail(droplet_id)

        expect { snap_runner }
          .to raise_error(DoSnapshot::DropletShutdownError)
      end
    end

    context 'when no snapshot created' do
      it 'raised with error' do
        stub_droplet_snapshot_fail(droplet_id, snapshot_name)

        expect { snap_runner }
          .to raise_error(DoSnapshot::SnapshotCreateError)
      end
    end
  end

  describe '.stop_droplet' do
    it 'when raised with error' do
      stub_droplet_stop_fail(droplet_id)
      load_options
      instance = cmd.api.droplet droplet_id
      droplet = instance.droplet
      expect { cmd.stop_droplet(droplet) }
        .to raise_error(DoSnapshot::DropletShutdownError)
    end

    it 'when stopped' do
      stub_droplet_stop(droplet_id)
      load_options
      instance = cmd.api.droplet droplet_id
      droplet = instance.droplet
      expect { cmd.stop_droplet(droplet) }
        .not_to raise_error
    end
  end

  describe '.create_snapshot' do
    it 'when raised with error' do
      stub_droplet_snapshot_fail(droplet_id, snapshot_name)
      load_options
      instance = cmd.api.droplet droplet_id
      droplet = instance.droplet
      expect { cmd.create_snapshot(droplet) }
        .to raise_error(DoSnapshot::SnapshotCreateError)
    end

    it 'when snapshot is created' do
      stub_droplet_snapshot(droplet_id, snapshot_name)
      load_options
      instance = cmd.api.droplet droplet_id
      droplet = instance.droplet
      expect { cmd.create_snapshot(droplet) }
        .not_to raise_error
    end
  end

  describe '.fail_power_off' do
    it 'when success' do
      stub_droplet_inactive(droplet_id)

      expect { cmd.fail_power_off(DoSnapshot::DropletShutdownError.new(droplet_id)) }
        .not_to raise_error
      expect(log.buffer)
        .to include 'Power On has been requested.'
    end

    it 'with request error' do
      stub_droplet_fail(droplet_id)

      expect { cmd.fail_power_off(DoSnapshot::DropletShutdownError.new(droplet_id)) }
        .to raise_error
      expect(log.buffer)
        .to include 'Droplet id: 100823 is Failed to Power Off.'
      expect(log.buffer)
        .to include 'Droplet Not Found'
    end

    it 'with start error' do
      stub_droplet_inactive(droplet_id)
      stub_droplet_start_fail(droplet_id)
      stub_event_fail(event_id)

      expect { cmd.fail_power_off(DoSnapshot::DropletShutdownError.new(droplet_id)) }
        .not_to raise_error
      expect(log.buffer)
        .to include 'Power On failed to request.'
    end
  end

  before(:each) do
    stub_all_api(nil, true)
    log.buffer = %w()
    log.verbose = false
    log.quiet = true
  end

  def load_options(options = nil)
    options ||= default_options
    cmd.send('api=', nil)
    cmd.load_options(options, [:log, :mail, :smtp, :trace, :digital_ocean_client_id, :digital_ocean_api_key])
  end

  def snap_runner
    load_options
    cmd.snap
  end
end
