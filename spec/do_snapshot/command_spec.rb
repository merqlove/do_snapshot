# -*- encoding : utf-8 -*-
require 'spec_helper'

describe DoSnapshot::Command do
  include_context 'spec'
  include_context 'uri_helpers'

  subject(:log)     { DoSnapshot::Log }

  describe '.snap' do
    context 'when success' do
      it 'sends success message' do
        expect { snap_runner }
          .not_to raise_error
        expect(log.buffer)
          .to include 'All operations has been finished.'
      end
    end

    context 'when snapshot not cleanup' do
      it 'sends cleanup message' do
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
      it 'raised with droplet list error' do
        stub_droplets_fail

        expect { snap_runner }
          .to raise_error(DoSnapshot::DropletListError)
      end
    end

    # TODO: MUST HAVE! Now when this two works others can fail...
    #
    # context 'when droplet failed for shutdown' do
    #   it 'raised with shutdown error' do
    #     fail = stub_droplet_stop_fail(droplet_id)
    #
    #     expect { snap_runner }
    #       .to raise_error(DoSnapshot::DropletShutdownError)
    #
    #     remove_request_stub(fail)
    #   end
    # end
    #
    # context 'when no snapshot created' do
    #   it 'raised with snapshot create error' do
    #     no_snapshot = stub_droplet_snapshot_fail(droplet_id, snapshot_name)
    #
    #     expect { snap_runner }
    #       .to raise_error(DoSnapshot::SnapshotCreateError)
    #
    #     remove_request_stub(no_snapshot)
    #   end
    # end
  end

  describe  '.fail_power_off' do
    it 'when success' do
      stub_droplet_inactive(droplet_id)

      expect { @cmd.fail_power_off(DoSnapshot::DropletShutdownError.new(droplet_id)) }
        .not_to raise_error
      expect(log.buffer)
        .to include 'Power On has been requested.'
    end

    it 'with request error' do
      stub_droplet_fail(droplet_id)

      expect { @cmd.fail_power_off(DoSnapshot::DropletShutdownError.new(droplet_id)) }
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

      expect { @cmd.fail_power_off(DoSnapshot::DropletShutdownError.new(droplet_id)) }
        .not_to raise_error
      expect(log.buffer)
        .to include 'Power On failed to request.'
    end
  end

  after(:each) do
    # WebMock.reset!
    stub_cleanup
  end

  before(:each) do
    @cmd = DoSnapshot::Command.dup
    stub_all_api(nil, true)
    log.buffer = %w()
    log.quiet = true
  end

  def snap_runner(options = nil)
    options ||= default_options
    @cmd.snap(options, [:log, :trace, :digital_ocean_client_id, :digital_ocean_api_key])
  end
end
