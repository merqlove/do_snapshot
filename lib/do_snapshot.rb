# -*- encoding : utf-8 -*-
require_relative 'do_snapshot/version'

# Used primary for creating snapshot's as backups for DigitalOcean
#
module DoSnapshot
  # Standard Request Exception. When we don't need droplet instance id.
  #
  class RequestError < StandardError; end

  # Base Exception for cases when we need id for log and/or something actions.
  #
  class RequestActionError < RequestError
    attr_reader :id

    def initialize(*args)
      @id = args[0]
    end
  end

  # Droplet must be powered off before snapshot operation!
  #
  class DropletShutdownError < RequestActionError
    def initialize(*args)
      Log.error "Droplet id: #{args[0]} is Failed to Power Off."
      super
    end
  end

  # When snapshot create operation is failed.
  # It can be because of something wrong with droplet or Digital Ocean API.
  #
  class SnapshotCreateError < RequestActionError
    def initialize(*args)
      Log.error "Droplet id: #{args[0]} is Failed to Snapshot."
      super
    end
  end

  # When Digital Ocean API say us that not found droplet by id.
  # Or something wrong happened.
  #
  class DropletFindError < RequestError
    def initialize(*args)
      Log.error 'Droplet Not Found'
      super
    end
  end

  # When Digital Ocean API cannot retrieve list of droplets.
  # Sometimes it connection problem or DigitalOcean API maintenance.
  #
  class DropletListError < RequestError
    def initialize(*args)
      Log.error 'Droplet Listing is failed to retrieve'
      super
    end
  end

  # When Digital Ocean API cannot remove old images.
  # Sometimes it connection problem or DigitalOcean API maintenance.
  #
  class SnapshotCleanupError < RequestError; end
end
