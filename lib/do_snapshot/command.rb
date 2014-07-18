require 'thread'
require 'do_snapshot/api'

module DoSnapshot
  # Our commands live here :)
  #
  class Command # rubocop:disable ClassLength
    class << self
      def snap(options, skip)
        return unless options

        options.each_pair do |key, option|
          send("#{key}=", option) unless skip.include? key
        end

        Log.info 'Start performing operations'
        work_with_droplets
        Log.info 'All operations has been finished.'

        Mail.notify if notify && !quiet
      end

      def fail_power_on(e)
        return unless e && e.id
        api.start_droplet(e.id)
      rescue
        raise DropletFindError, e.message, e.backtrace
      end

      protected

      attr_accessor :droplets, :mail, :smtp, :exclude, :only, :api
      attr_accessor :delay, :keep, :quiet, :stop, :clean

      attr_writer :notify, :threads, :api

      def api
        @api ||= API.new(delay)
      end

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
        self.droplets = api.droplets.droplets
      end

      # Dispatch received droplets, each by each.
      #
      def dispatch_droplets
        droplets.each do |droplet|
          id = droplet.id.to_s
          next if exclude.include? id
          next if !only.empty? && !only.include?(id)

          instance = api.droplet id

          prepare_instance instance.droplet
        end
      end

      # Join threads
      #
      def thread_chain
        threads.each { |t| t.join }
      end

      # Run threads
      #
      def thread_runner(instance)
        threads << Thread.new do
          Log.debug 'Shutting down droplet.'
          stop_droplet instance
          create_snapshot instance
        end
      end

      # Preparing instance to take snapshot.
      # Instance must be powered off first!
      #
      def prepare_instance(instance)
        return unless instance
        Log.info "Preparing droplet id: #{instance.id} name: #{instance.name} to take snapshot."
        return if too_much_snapshots(instance)
        thread_runner(instance)
      end

      def too_much_snapshots(instance)
        # noinspection RubyResolve
        if instance.snapshots.size >= keep && stop
          Log.warning warning_size(instance.id, instance.name, keep)
          self.notify = true
          return true
        end
        false
      end

      def stop_droplet(instance)
        api.stop_droplet(instance.id) unless instance.status.include? 'off'
      end

      # Trying to create a snapshot.
      #
      def create_snapshot(instance) # rubocop:disable MethodLength
        Log.info "Start creating snapshot for droplet id: #{instance.id} name: #{instance.name}."

        today         = DateTime.now
        name          = "#{instance.name}_#{today.strftime('%Y_%m_%d')}"
        # noinspection RubyResolve
        snapshot_size = instance.snapshots.size

        Log.debug 'Wait until snapshot will be created.'

        api.create_snapshot instance.id, name

        snapshot_size += 1

        Log.info "Snapshot name: #{name} created successfully."
        Log.info "Droplet id: #{instance.id} name: #{instance.name} snapshots: #{snapshot_size}."

        # Cleanup snapshots.
        cleanup_snapshots instance, snapshot_size if clean
      rescue => e
        case e.class
        when SnapshotCleanupError
          raise e.class, e.message, e.backtrace
        else
          raise SnapshotCreateError.new(instance.id), e.message, e.backtrace
        end
      end

      # Cleanup our snapshots.
      #
      def cleanup_snapshots(instance, size)
        return unless size > keep

        Log.warning warning_size(instance.id, instance.name, size)

        size = size - keep - 1
        self.notify = true

        Log.debug "Cleaning up snapshots for droplet id: #{instance.id} name: #{instance.name}."

        api.cleanup_snapshots instance, size
      rescue => e
        raise SnapshotCleanupError, e.message, e.backtrace
      end

      def warning_size(id, name, keep)
        "For droplet with id: #{id} and name: #{name} the maximum number #{keep} of snapshots is reached."
      end
    end
  end
end
