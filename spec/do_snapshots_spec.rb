# -*- encoding : utf-8 -*-
require 'spec_helper'

describe DoSnapshot do
  include_context 'spec'

  subject(:log) { DoSnapshot::Log }

  describe DoSnapshot::DropletFindError do
    subject(:error) { described_class }

    it 'should work' do
      error.new
      expect(log.buffer)
        .to include 'Droplet Not Found'
    end
  end

  describe DoSnapshot::DropletListError do
    subject(:error) { described_class }

    it 'should work' do
      error.new
      expect(log.buffer)
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
      expect(log.buffer)
        .to include "Droplet id: #{droplet_id} is Failed to Power Off."
    end
  end

  describe DoSnapshot::SnapshotCreateError do
    subject(:error) { described_class }

    it 'should work' do
      error.new(droplet_id)
      expect(log.buffer)
        .to include "Droplet id: #{droplet_id} is Failed to Snapshot."
    end
  end

  before(:each) do
    log.buffer = %w()
    log.verbose = false
    log.quiet = true
  end
end
