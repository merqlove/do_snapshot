# -*- encoding : utf-8 -*-
require_relative 'do_snapshot/version'
require_relative 'do_snapshot/configuration'

# Used primary for creating snapshot's as backups for DigitalOcean
#
module DoSnapshot
  class << self
    attr_accessor :logger, :mailer

    def configure
      yield(config)
    end

    def reconfigure
      @config = Configuration.new
      yield(config)
    end

    def config
      @config ||= Configuration.new
    end

    def cleanup
      logger.close if logger
      @logger = nil
      @mailer = nil
      @config = nil
    end
  end

  # Standard Request Exception. When we don't need droplet instance id.
  #
  class RequestError < StandardError; end

  # Every call must have keys in environment or via params.
  #
  class NoKeysError < StandardError; end

  # Every call must have token in environment or via params.
  #
  class NoTokenError < StandardError; end

  # Protocol must exist.
  #
  class NoProtocolError < StandardError; end

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
      DoSnapshot.logger.error "Droplet id: #{args[0]} is Failed to Power Off."
      super
    end
  end

  # When snapshot create operation is failed.
  # It can be because of something wrong with droplet or Digital Ocean API.
  #
  class SnapshotCreateError < RequestActionError
    def initialize(*args)
      DoSnapshot.logger.error "Resource id: #{args[0]} is Failed to Snapshot."
      super
    end
  end

  # When Digital Ocean API say us that not found droplet by id.
  # Or something wrong happened.
  #
  class DropletFindError < RequestError
    def initialize(*args)
      DoSnapshot.logger.error "Droplet id: #{args[0]} Not Found"
      super
    end
  end

  # When Droplet not Powered Off!
  #
  class DropletPowerError < RequestError
    def initialize(*args)
      DoSnapshot.logger.error "Droplet id: #{args[0]} must be Powered Off!"
      super
    end
  end

  # When Event is failed!
  #
  class EventError < RequestError
    def initialize(*args)
      DoSnapshot.logger.error "Event id: #{args[0]} is failed!"
      super
    end
  end

  # When Digital Ocean API cannot retrieve list of droplets.
  # Sometimes it connection problem or DigitalOcean API maintenance.
  #
  class DropletListError < RequestError
    def initialize(*args)
      DoSnapshot.logger.error 'Droplet Listing is failed to retrieve'
      super
    end
  end

  # When Digital Ocean API cannot remove old images.
  # Sometimes it connection problem or DigitalOcean API maintenance.
  #
  class SnapshotCleanupError < RequestError; end

  # When Digital Ocean API say us that not found volume by id.
  # Or something wrong happened.
  #
  class VolumeFindError < RequestError
    def initialize(*args)
      DoSnapshot.logger.error "Volume id: #{args[0]} Not Found"
      super
    end
  end

  # When Digital Ocean API cannot retrieve list of volumes.
  # Sometimes it connection problem or DigitalOcean API maintenance.
  #
  class VolumeListError < RequestError
    def initialize(*args)
      DoSnapshot.logger.error 'Volume Listing is failed to retrieve'
      super
    end
  end

  # When Digital Ocean API cannot retrieve list of volumes.
  # Sometimes it connection problem or DigitalOcean API maintenance.
  #
  class SnapshotListError < RequestError
    def initialize(*args)
      DoSnapshot.logger.error 'Snapshot Listing is failed to retrieve'
      super
    end
  end

end
