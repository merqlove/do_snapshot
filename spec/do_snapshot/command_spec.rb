# -*- encoding : utf-8 -*-
# frozen_string_literal: true
require 'spec_helper'

RSpec.describe DoSnapshot::Command do
  include DoSnapshot::RSpec::Environment
  include DoSnapshot::RSpec::UriHelpers

  subject(:cmd)     { DoSnapshot::Command.new }
  subject(:log)     { DoSnapshot::Log }

  describe 'V2' do
    include DoSnapshot::RSpec::ApiV2Helpers

    describe '.snap' do
      context 'when success' do
        it 'sends message' do
          stub_droplet_inactive(droplet_id)
          expect { snap_runner }
            .not_to raise_error
          expect(DoSnapshot.logger.buffer)
            .to include 'All operations has been finished.'
        end
      end

      context 'when snapshot not cleanup' do
        it 'sends message' do
          stub_droplet_inactive(droplet_id)
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
            .not_to raise_error
          expect(DoSnapshot.logger.buffer)
            .to include "Droplet id: #{droplet_id} is Failed to Power Off."
        end
      end

      context 'when no snapshot created' do
        it 'raised with error' do
          stub_droplet_inactive(droplet_id)
          stub_droplet_snapshot_fail(droplet_id, snapshot_name)

          expect { snap_runner }
            .to raise_error(DoSnapshot::SnapshotCreateError)
        end
      end

      context 'when droplet not stopped' do
        it 'skipped droplet' do
          stub_droplet_stop_fail(droplet_id)

          expect { snap_runner }
            .not_to raise_error
          expect(DoSnapshot.logger.buffer)
            .to include "Droplet id: #{droplet_id} is Failed to Power Off."
        end
      end
    end

    describe '.power_on_failed_droplets' do
      it 'when nothing' do
        stub_droplet_start(droplet_id)
        stub_droplet(droplet_id)

        load_options
        cmd.processed_droplet_ids << droplet_id
        expect { cmd.power_on_failed_droplets }
          .not_to raise_error
        expect(DoSnapshot.logger.buffer)
          .not_to include "Droplet id: #{droplet_id} is requested for Power On."
      end

      it 'when one' do
        stub_droplet_start(droplet_id)
        stub_droplet_inactive(droplet_id)

        load_options
        cmd.processed_droplet_ids << droplet_id
        expect { cmd.power_on_failed_droplets }
          .not_to raise_error
        expect(DoSnapshot.logger.buffer)
          .to include "Droplet id: #{droplet_id} is requested for Power On."
      end
    end

    describe '.stop_droplet by power status' do
      it 'when raised with error' do
        stub_droplet_stop_fail(droplet_id)
        load_options(stop_by_power: true, shutdown: true)
        droplet = cmd.api.droplet droplet_id
        expect { cmd.stop_droplet(droplet) }
          .not_to raise_error
        expect(cmd.stop_droplet(droplet))
          .to be_falsey
      end

      it 'when stopped' do
        stub_droplet_inactive(droplet_id)
        stub_droplet_stop(droplet_id)
        load_options(stop_by_power: true, shutdown: true)
        droplet = cmd.api.droplet droplet_id
        expect { cmd.stop_droplet(droplet) }
          .not_to raise_error
        expect(cmd.stop_droplet(droplet))
          .to be_truthy
      end

      it 'when nothing' do
        stub_droplet(droplet_id)
        load_options(stop_by_power: true, shutdown: false)
        droplet = cmd.api.droplet droplet_id
        expect { cmd.stop_droplet(droplet) }
          .not_to raise_error
        expect(cmd.stop_droplet(droplet))
          .to be_truthy
      end
    end

    describe '.stop_droplet by event' do
      it 'when raised with error' do
        stub_droplet_stop_fail(droplet_id)
        load_options
        droplet = cmd.api.droplet droplet_id
        expect { cmd.stop_droplet(droplet) }
          .not_to raise_error
        expect(cmd.stop_droplet(droplet))
          .to be_falsey
      end

      it 'when stopped' do
        stub_droplet_inactive(droplet_id)
        stub_droplet_stop(droplet_id)
        load_options
        droplet = cmd.api.droplet droplet_id
        expect { cmd.stop_droplet(droplet) }
          .not_to raise_error
        expect(cmd.stop_droplet(droplet))
          .to be_truthy
      end

      it 'when nothing' do
        stub_droplet(droplet_id)
        load_options(shutdown: false)
        droplet = cmd.api.droplet droplet_id
        expect { cmd.stop_droplet(droplet) }
          .not_to raise_error
        expect(cmd.stop_droplet(droplet))
          .to be_truthy
      end
    end

    describe '.create_snapshot' do
      it 'when raised with error' do
        stub_droplet_inactive(droplet_id)
        stub_droplet_snapshot_fail(droplet_id, snapshot_name)
        load_options
        droplet = cmd.api.droplet droplet_id
        expect { cmd.create_snapshot(droplet) }
          .to raise_error(DoSnapshot::SnapshotCreateError)
      end

      it 'when snapshot is created' do
        stub_droplet_inactive(droplet_id)
        stub_droplet_snapshot(droplet_id, snapshot_name)
        load_options
        droplet = cmd.api.droplet droplet_id
        cmd.create_snapshot(droplet)
        expect { cmd.create_snapshot(droplet) }
          .not_to raise_error
      end

      it 'when snapshot is created with no shutdown' do
        stub_droplet(droplet_id)
        stub_droplet_snapshot(droplet_id, snapshot_name)
        load_options(shutdown: false)
        droplet = cmd.api.droplet droplet_id
        cmd.create_snapshot(droplet)
        expect(DoSnapshot.logger.buffer)
          .not_to include "Droplet id: #{droplet_id} must be Powered Off!"
        expect { cmd.create_snapshot(droplet) }
          .not_to raise_error
      end

      it 'when droplet is running' do
        stub_droplet(droplet_id)
        load_options
        droplet = cmd.api.droplet droplet_id
        cmd.create_snapshot(droplet)
        expect { cmd.create_snapshot(droplet) }
          .not_to raise_error
        expect(DoSnapshot.logger.buffer)
          .to include "Droplet id: #{droplet_id} must be Powered Off!"
      end
    end

    describe '.fail_power_off' do
      it 'when success' do
        stub_droplet_inactive(droplet_id)
        load_options(shutdown: true)
        expect { cmd.fail_power_off(DoSnapshot::DropletShutdownError.new(droplet_id)) }
          .not_to raise_error
        expect(DoSnapshot.logger.buffer)
          .to include "Droplet id: #{droplet_id} is requested for Power On."
      end

      it 'not rescue when shutdown is true' do
        stub_droplet_fail(droplet_id)
        load_options(shutdown: false)
        expect { cmd.fail_power_off(DoSnapshot::SnapshotCreateError.new(droplet_id)) }
          .not_to raise_error
        expect(DoSnapshot.logger.buffer)
          .to include "Droplet id: #{droplet_id} is Failed to Snapshot."
      end

      it 'with request error' do
        stub_droplet_fail(droplet_id)
        load_options(shutdown: true)
        expect { cmd.fail_power_off(DoSnapshot::DropletShutdownError.new(droplet_id)) }
          .to raise_error(DoSnapshot::DropletFindError)
        expect(DoSnapshot.logger.buffer)
          .to include 'Droplet id: 100823 is Failed to Power Off.'
        expect(DoSnapshot.logger.buffer)
          .to include "Droplet id: #{droplet_id} Not Found"
      end

      it 'with start error' do
        stub_droplet_inactive(droplet_id)
        stub_droplet_start_done(droplet_id)
        load_options(shutdown: true)
        expect { cmd.fail_power_off(DoSnapshot::DropletShutdownError.new(droplet_id)) }
          .not_to raise_error
        expect(DoSnapshot.logger.buffer)
          .to include "Droplet id: #{droplet_id} is failed to request for Power On."
      end
    end
  end

  before(:each) do
    stub_all_api(nil, true)
    DoSnapshot.logger.buffer = %w()
    DoSnapshot.logger.verbose = false
    DoSnapshot.logger.quiet = true
  end

  def load_options(options = nil)
    options ||= default_options.merge(protocol: 2)
    cmd.load_options(options, [:log, :mail, :smtp, :trace, :digital_ocean_access_token])
  end

  def snap_runner
    load_options
    cmd.snap
  end
end
