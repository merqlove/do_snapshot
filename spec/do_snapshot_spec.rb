# -*- encoding : utf-8 -*-
require 'spec_helper'

RSpec.describe DoSnapshot do
  include_context 'spec'

  describe DoSnapshot::DropletFindError do
    subject(:error) { described_class }

    it 'should work' do
      error.new
      expect(DoSnapshot.logger.buffer)
        .to include 'Droplet Not Found'
    end
  end

  describe DoSnapshot::DropletPowerError do
    subject(:error) { described_class }

    it 'should work' do
      error.new(droplet_id)
      expect(DoSnapshot.logger.buffer)
        .to include "Droplet id: #{droplet_id} must be Powered Off!"
    end
  end

  describe DoSnapshot::DropletListError do
    subject(:error) { described_class }

    it 'should work' do
      error.new
      expect(DoSnapshot.logger.buffer)
        .to include 'Droplet Listing is failed to retrieve'
    end
  end

  describe DoSnapshot::SnapshotCleanupError do
    subject(:error) { described_class }

    it 'should be' do
      expect { error.new }
        .not_to raise_error
    end
  end

  describe DoSnapshot::DropletShutdownError do
    subject(:error) { described_class }

    it 'should work' do
      error.new(droplet_id)
      expect(DoSnapshot.logger.buffer)
        .to include "Droplet id: #{droplet_id} is Failed to Power Off."
    end
  end

  describe DoSnapshot::SnapshotCreateError do
    subject(:error) { described_class }

    it 'should work' do
      error.new(droplet_id)
      expect(DoSnapshot.logger.buffer)
        .to include "Droplet id: #{droplet_id} is Failed to Snapshot."
    end
  end
end
