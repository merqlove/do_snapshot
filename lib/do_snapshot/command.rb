# -*- encoding : utf-8 -*-
# frozen_string_literal: true
require_relative 'adapter'

module DoSnapshot
  # Our commands live here :)
  #
  class Command # rubocop:disable ClassLength
    include DoSnapshot::Helpers

    RESET_OPTIONS = [:droplets, :exclude, :only, :keep, :quiet,
                     :stop, :clean, :timeout, :shutdown, :delay,
                     :protocol, :threads, :api]

    def initialize(*args)
      load_options(*args)
    end

    def snap
      logger.info 'Start performing operations'
      work_with_droplets
      power_on_failed_droplets
      logger.info 'All operations has been finished.'

      mailer.notify if mailer && notify && !quiet
    end

    def fail_power_off(e)
      return unless shutdown
      return unless e && e.id
      api.start_droplet(e.id)
    rescue
      raise DropletFindError, e.message, e.backtrace
    end

    def load_options(options = {}, skip = %w())
      reset_options
      options.each_pair do |key, option|
        send("#{key}=", option) unless skip.include?(key)
      end if options
    end

    def reset_options
      RESET_OPTIONS.each do |key|
        send("#{key}=", nil)
      end
    end

    def stop_droplet(droplet)
      return true unless shutdown
      logger.debug 'Shutting down droplet.'
      api.stop_droplet(droplet.id) unless droplet.status.include? 'off'
      true
    rescue => e
      logger.error e.message
      false
    end

    # Trying to create a snapshot.
    #
    def create_snapshot(droplet) # rubocop:disable MethodLength,Metrics/AbcSize
      fail_if_shutdown(droplet)

      logger.info "Start creating snapshot for droplet id: #{droplet.id} name: #{droplet.name}."

      today         = DateTime.now
      name          = "#{droplet.name}_#{today.strftime('%Y_%m_%d')}"
      # noinspection RubyResolve
      snapshot_size = api.snapshots(droplet).size

      logger.debug 'Wait until snapshot will be created.'

      api.create_snapshot droplet.id, name

      snapshot_size += 1

      logger.info "Snapshot name: #{name} created successfully."
      logger.info "Droplet id: #{droplet.id} name: #{droplet.name} snapshots: #{snapshot_size}."

      # Cleanup snapshots.
      cleanup_snapshots droplet, snapshot_size if clean
    rescue => e
      case e.class.to_s
      when 'DoSnapshot::SnapshotCleanupError'
        raise e.class, e.message, e.backtrace
      when 'DoSnapshot::DropletPowerError'
        return
      else
        raise SnapshotCreateError.new(droplet.id), e.message, e.backtrace
      end
    end

    def power_on_failed_droplets
      processed_droplet_ids
        .select { |id| api.inactive?(id) }
        .each   { |id| api.power_on(id) }
    end

    # API launcher
    #
    def api
      @api ||= DoSnapshot::Adapter.api(protocol, delay: delay, timeout: timeout, stop_by: stop_by)
    end

    # Processed droplets
    #
    def processed_droplet_ids
      @droplet_ids ||= %w()
    end

    protected

    attr_accessor :droplets, :exclude, :only
    attr_accessor :keep, :quiet, :shutdown, :stop, :stop_by_power, :clean, :timeout, :delay, :protocol

    attr_writer :threads, :api

    def notify
      @notify ||= false
    end

    def threads
      @threads ||= []
    end

    def stop_by
      stop_by_power ? :power_status : :event_status
    end

    # Working with list of droplets.
    #
    def work_with_droplets
      load_droplets
      dispatch_droplets
      logger.debug 'Working with list of DigitalOcean droplets'
      thread_chain
    end

    # Getting droplets list from API.
    # And store into object.
    #
    def load_droplets
      logger.debug 'Loading list of DigitalOcean droplets'
      self.droplets = api.droplets
    end

    # Dispatch received droplets, each by each.
    #
    def dispatch_droplets
      droplets.each do |droplet|
        id = droplet.id.to_s
        next if exclude.include? id
        next unless only.empty? || only.include?(id)

        prepare_droplet id, droplet.name
      end
    end

    # Join threads
    #
    def thread_chain
      threads.each(&:join)
    end

    # Run threads
    #
    def thread_runner(droplet)
      threads << Thread.new do
        create_snapshot droplet if stop_droplet(droplet)
      end
    end

    # Preparing droplet to take a snapshot.
    # Droplet instance must be powered off first!
    #
    def prepare_droplet(id, name)
      logger.debug "Droplet id: #{id} name: #{name}\n"
      droplet = api.droplet id

      return unless droplet
      logger.info "Preparing droplet id: #{droplet.id} name: #{droplet.name} to take snapshot."
      return if too_much_snapshots?(droplet)
      processed_droplet_ids << droplet.id
      thread_runner(droplet)
    end

    def too_much_snapshots?(instance)
      return false if api.snapshots(instance).size < keep
      warning_size(instance.id, instance.name, keep)
      stop ? true : false
    end

    def fail_if_shutdown(droplet)
      return unless shutdown
      fail DropletPowerError.new(droplet.id), droplet.name unless api.inactive?(droplet.id)
    end

    # Cleanup our snapshots.
    #
    def cleanup_snapshots(droplet, size) # rubocop:disable Metrics/AbcSize
      return unless size > keep

      warning_size(droplet.id, droplet.name, size)

      logger.debug "Cleaning up snapshots for droplet id: #{droplet.id} name: #{droplet.name}."

      api.cleanup_snapshots(droplet, size - keep - 1)
    rescue => e
      raise SnapshotCleanupError, e.message, e.backtrace
    end

    # Helpers
    #
    def warning_size(id, name, keep)
      message = "For droplet with id: #{id} and name: #{name} the maximum number #{keep} of snapshots is reached."
      logger.warn message
      @notify = true
    end
  end
end
