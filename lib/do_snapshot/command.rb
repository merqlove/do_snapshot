# -*- encoding : utf-8 -*-
require_relative 'adapter'

module DoSnapshot
  # Our commands live here :)
  #
  class Command # rubocop:disable ClassLength
    include DoSnapshot::Helpers

    RESET_OPTIONS = [:resources, :exclude, :only, :keep, :quiet,
                     :stop, :clean, :timeout, :shutdown, :delay,
                     :protocol, :threads, :api, :resource_types, :resource_type]

    def initialize(*args)
      load_options(*args)
    end

    def snap
      logger.info 'Start performing operations'
      resource_types.split(",").each do |resource_type|
        # Check option resource_type
        raise "Invalid resource_type. Valid values are 'droplets' or 'volumes'." unless ['droplets', 'volumes'].include?(resource_type)

        self.resource_type = resource_type
        work_with_resources
        power_on_failed_droplets if droplets?
        clean_variables
      end
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
      return if volumes?
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
    def create_snapshot(resource) # rubocop:disable MethodLength,Metrics/AbcSize
      self.resource_type ||= 'droplets'
      fail_if_shutdown(resource) if droplets?

      logger.info "Start creating snapshot for #{resource_type_singular} id: #{resource.id} name: #{resource.name}."

      today         = DateTime.now
      name          = "#{resource.name}_#{today.strftime('%Y-%m-%d-%H-%M')}"
      # noinspection RubyResolve
      snapshot_size = snapshot_size(resource)

      logger.debug 'Wait until snapshot will be created.'
      api.create_snapshot resource.id, name, resource_type_singular

      snapshot_size += 1

      logger.info "Snapshot name: #{name} created successfully."
      logger.info "#{resource_type_singular.capitalize} id: #{resource.id} name: #{resource.name} snapshots: #{snapshot_size}."

      # Cleanup snapshots.
      cleanup_snapshots resource, snapshot_size if clean
    rescue => e
      case e.class.to_s
      when 'DoSnapshot::SnapshotCleanupError'
        raise e.class, e.message, e.backtrace
      when 'DoSnapshot::DropletPowerError'
        return
      else
        raise SnapshotCreateError.new(resource.id, resource_type_singular), e.message, e.backtrace
      end
    end

    def power_on_failed_droplets
      processed_ids
        .select { |id| api.inactive?(id) }
        .each   { |id| api.power_on(id) }
    end

    # API launcher
    #
    def api
      @api ||= DoSnapshot::Adapter.api(protocol, delay: delay, timeout: timeout, stop_by: stop_by)
    end

    # Processed resources
    #
    def processed_ids
      @processed_ids ||= %w()
    end

    def clean_variables
      @processed_ids = nil
      @threads = []
    end

    protected

    attr_accessor :resources, :exclude, :only
    attr_accessor :keep, :quiet, :shutdown, :stop, :stop_by_power, :clean, :timeout, :delay, :protocol, :resource_types, :resource_type

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

    # Working with list of droplets or volumes.
    #
    def work_with_resources
      load_resources
      dispatch_resources
      logger.debug "Working with list of DigitalOcean #{resource_type}"
      thread_chain
    end

    # Getting droplets or volumes list from API.
    # And store into object.
    #
    def load_resources
      logger.debug "Loading list of DigitalOcean #{resource_type}"
      self.resources = api.send(resource_type)
    end

    # Dispatch received droplets, each by each.
    #
    def dispatch_resources
      resources.each do |resource|
        id = resource.id.to_s
        next if exclude.include? id
        next unless only.empty? || only.include?(id)

        prepare_resource id, resource.name
      end
    end

    # Join threads
    #
    def thread_chain
      threads.each(&:join)
    end

    # Run threads
    #
    def thread_runner(resource)
      threads << Thread.new do
        create_snapshot resource if volumes? or stop_droplet(resource)
      end
    end

    # Preparing droplet or volume to take a snapshot.
    # Droplet instance must be powered off first!
    #
    def prepare_resource(id, name)
      logger.debug "#{resource_type.capitalize} id: #{id} name: #{name}\n"
      resource = api.send(resource_type_singular, id)

      return unless resource
      logger.info "Preparing #{resource_type_singular} id: #{resource.id} name: #{resource.name} to take snapshot."
      return if too_much_snapshots?(resource)
      processed_ids << resource.id
      thread_runner(resource)
    end

    def too_much_snapshots?(instance)
      return false if snapshot_size(instance) < keep
      warning_size(instance.id, instance.name, keep)
      stop ? true : false
    end

    def snapshot_size(instance)
      api.snapshot_ids(instance, resource_type_singular).size
    end

    def fail_if_shutdown(droplet)
      return unless shutdown
      fail DropletPowerError.new(droplet.id), droplet.name unless api.inactive?(droplet.id)
    end

    # Cleanup our snapshots.
    #
    def cleanup_snapshots(resource, size) # rubocop:disable Metrics/AbcSize
      return unless size > keep

      warning_size(resource.id, resource.name, keep)

      logger.debug "Cleaning up snapshots for #{resource_type_singular} id: #{resource.id} name: #{resource.name}."

      api.cleanup_snapshots(resource, size - keep - 1, resource_type_singular)
    rescue => e
      raise SnapshotCleanupError, e.message, e.backtrace
    end

    # Helpers
    #
    def warning_size(id, name, keep)
      message = "For #{resource_type_singular} with id: #{id} and name: #{name} the maximum number #{keep} of snapshots is reached."
      logger.warn message
      @notify = true
    end

    def droplets?
      resource_type == 'droplets'
    end

    def volumes?
      resource_type == 'volumes'
    end

    def resource_type_singular
      case resource_type
      when 'droplets'
        'droplet'
      when 'volumes'
        'volume'
      end
    end
  end
end
