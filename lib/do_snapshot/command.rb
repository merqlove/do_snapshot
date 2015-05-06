# -*- encoding : utf-8 -*-
require_relative 'adapter'

module DoSnapshot
  # Our commands live here :)
  #
  class Command # rubocop:disable ClassLength
    class << self
      def snap
        Log.info 'Start performing operations'
        work_with_droplets
        Log.info 'All operations has been finished.'

        Mail.notify if notify && !quiet
      end

      def load_options(options = {}, skip = %w())
        options.each_pair do |key, option|
          send("#{key}=", option) unless skip.include?(key)
        end if options
      end

      def fail_power_off(e)
        return unless e && e.id
        api.start_droplet(e.id)
      rescue
        raise DropletFindError, e.message, e.backtrace
      end

      def stop_droplet(droplet)
        Log.debug 'Shutting down droplet.'
        api.stop_droplet(droplet.id) unless droplet.status.include? 'off'
      end

      # Trying to create a snapshot.
      #
      def create_snapshot(droplet) # rubocop:disable MethodLength,Metrics/AbcSize
        Log.info "Start creating snapshot for droplet id: #{droplet.id} name: #{droplet.name}."

        today         = DateTime.now
        name          = "#{droplet.name}_#{today.strftime('%Y_%m_%d')}"
        # noinspection RubyResolve
        snapshot_size = api.snapshots(droplet).size

        Log.debug 'Wait until snapshot will be created.'

        api.create_snapshot droplet.id, name

        snapshot_size += 1

        Log.info "Snapshot name: #{name} created successfully."
        Log.info "Droplet id: #{droplet.id} name: #{droplet.name} snapshots: #{snapshot_size}."

        # Cleanup snapshots.
        cleanup_snapshots droplet, snapshot_size if clean
      rescue => e
        case e.class.to_s
        when 'DoSnapshot::SnapshotCleanupError'
          raise e.class, e.message, e.backtrace
        else
          raise SnapshotCreateError.new(droplet.id), e.message, e.backtrace
        end
      end

      def api
        @api ||= DoSnapshot::Adapter.api(protocol, delay: delay, timeout: timeout)
      end

      protected

      attr_accessor :droplets, :exclude, :only
      attr_accessor :keep, :quiet, :stop, :clean, :timeout, :delay, :protocol

      attr_writer :notify, :threads, :api

      def notify
        @notify ||= false
      end

      def threads
        @threads ||= []
      end

      # Working with list of droplets.
      #
      def work_with_droplets
        load_droplets
        dispatch_droplets
        Log.debug 'Working with list of DigitalOcean droplets'
        thread_chain
      end

      # Getting droplets list from API.
      # And store into object.
      #
      def load_droplets
        Log.debug 'Loading list of DigitalOcean droplets'
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
          stop_droplet droplet
          create_snapshot droplet
        end
      end

      # Preparing droplet to take a snapshot.
      # Droplet instance must be powered off first!
      #
      def prepare_droplet(id, name)
        Log.debug "Droplet id: #{id} name: #{name} "
        droplet = api.droplet id

        return unless droplet
        Log.info "Preparing droplet id: #{droplet.id} name: #{droplet.name} to take snapshot."
        return if too_much_snapshots(droplet)
        thread_runner(droplet)
      end

      def too_much_snapshots(instance)
        # noinspection RubyResolve
        return false unless api.snapshots(instance).size >= keep
        warning_size(instance.id, instance.name, keep)
        stop ? true : false
      end

      # Cleanup our snapshots.
      #
      def cleanup_snapshots(droplet, size) # rubocop:disable Metrics/AbcSize
        return unless size > keep

        warning_size(droplet.id, droplet.name, size)

        Log.debug "Cleaning up snapshots for droplet id: #{droplet.id} name: #{droplet.name}."

        api.cleanup_snapshots(droplet, size - keep - 1)
      rescue => e
        raise SnapshotCleanupError, e.message, e.backtrace
      end

      # Helpers
      #
      def warning_size(id, name, keep)
        message = "For droplet with id: #{id} and name: #{name} the maximum number #{keep} of snapshots is reached."
        Log.warning message
        self.notify = true
      end
    end
  end
end
