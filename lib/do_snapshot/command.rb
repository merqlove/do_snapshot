require 'digitalocean'
require 'thread'

module DoSnapshot
  # Our commands live here :)
  #
  class Command
    class << self
      def execute(options, skip)
        return unless options

        options.each_pair do |key, option|
          send("#{key}=", option) unless skip.include? key
        end

        Log.info 'Start performing operations'
        work_droplets
        Log.info 'All operations has been finished.'

        Log.notify if notify && !quiet
      end

      def fail_power_on(id)
        return unless id

        set_id
        instance = Digitalocean::Droplet.find(id)
        fail instance.message unless instance.status.include? 'OK'
        if instance.droplet.status.include? 'active'
          Log.info "Droplet id: #{id} failed to snapshot. But it still running."
        else
          Digitalocean::Droplet.power_on(id)
          Log.info "Droplet id: #{id} failed to snapshot. POWER ON has been requested."
        end
      end

      protected

      attr_accessor :droplets, :mail, :smtp, :exclude, :only
      attr_accessor :delay, :keep, :quiet, :stop, :clean

      attr_writer :notify, :threads

      def notify
        @notify ||= false
      end

      def threads
        @threads ||= []
      end

      # Getting droplets list from API.
      # And store into object.
      #
      def load_droplets
        set_id
        Log.debug 'Loading list of DigitalOcean droplets'
        droplets = Digitalocean::Droplet.all
        fail droplets.message unless droplets.status.include? 'OK'
        self.droplets = droplets.droplets
      end

      # Working with received list of droplets.
      #
      def work_droplets
        load_droplets
        Log.debug 'Working with list of DigitalOcean droplets'
        droplets.each do |droplet|
          id = droplet.id.to_s
          next if exclude.include? id
          next if !only.empty? && !only.include?(id)

          instance = Digitalocean::Droplet.find(id)
          fail instance.message unless instance.status.include? 'OK'

          prepare_instance instance.droplet
        end
        thread_chain
      end

      # Threads review
      #
      def thread_chain
        threads.each { |t| t.join }
      end

      # Preparing instance to take snapshot.
      # Instance must be powered off first!
      #
      def prepare_instance(instance)
        return unless instance
        Log.info "Preparing droplet id: #{instance.id} name: #{instance.name} to take snapshot."

        warning_size = "For droplet with id: #{instance.id} and name: #{instance.name} the maximum number #{keep} of snapshots is reached."

        if instance.snapshots.size >= keep && stop
          Log.warning warning_size
          self.notify = true
          return
        end

        # Stopping instance.
        Log.debug 'Shutting down droplet.'
        threads << Thread.new do
          begin
            unless instance.status.include? 'off'
              event = Digitalocean::Droplet.power_off(instance.id)
              if event.status.include? 'OK'
                sleep delay until get_event_status(event.event_id)
              end
            end
          rescue => e
            raise DropletShutdownError.new(instance.id), e.message, e.backtrace
          end

          # Create snapshot.
          create_snapshot instance, warning_size
        end
      end

      # Trying to create a snapshot.
      #
      def create_snapshot(instance, warning_size)
        Log.info "Start creating snapshot for droplet id: #{instance.id} name: #{instance.name}."

        today         = DateTime.now
        name          = "#{instance.name}_#{today.strftime('%Y_%m_%d')}"
        event         = Digitalocean::Droplet.snapshot(instance.id, name: name)
        snapshot_size = instance.snapshots.size

        if !event
          fail 'Something wrong with DigitalOcean or with your connection :)'
        elsif event && !event.status.include?('OK')
          fail event.message
        end

        Log.debug 'Wait until snapshot will be created.'

        sleep delay until get_event_status(event.event_id)

        snapshot_size += 1

        Log.info "Snapshot name: #{name} created successfully."
        Log.info "Droplet id: #{instance.id} name: #{instance.name} snapshots: #{snapshot_size}."

        if snapshot_size > keep
          Log.warning warning_size if snapshot_size > keep
          self.notify = true

          # Cleanup snapshots.
          cleanup_snapshots instance, (snapshot_size - keep - 1) if clean
        end
      rescue => e
        case e.class
        when SnapshotCleanupError
          raise
        else
          raise SnapshotCreateError.new(instance.id), e.message, e.backtrace
        end
      end

      # Cleanup our snapshots.
      #
      def cleanup_snapshots(instance, size)
        Log.debug "Cleaning up snapshots for droplet id: #{instance.id} name: #{instance.name}."

        (0..size).each do |i|
          snapshot = instance.snapshots[i]
          event = Digitalocean::Image.destroy(snapshot.id)

          if !event
            fail 'Something wrong with DigitalOcean or with your connection :)'
          elsif event && !event.status.include?('OK')
            fail event.message
          end

          Log.info "Snapshot name: #{snapshot.name} delete requested."
        end
      rescue => e
        raise SnapshotCleanupError.new(instance.id), e.message, e.backtrace
      end

      # Looking for event status.
      #
      # Before snapshot we to know that machine has powered off.
      #
      def get_event_status(id)
        event = Digitalocean::Event.find(id)
        fail event.message unless event.status.include?('OK')
        event.event.percentage && event.event.percentage.include?('100') ? true : false
      end

      # Set id's of Digital Ocean API.
      #
      def set_id
        Log.debug 'Setting DigitalOcean Id\'s.'
        Digitalocean.client_id = ENV['DIGITAL_OCEAN_CLIENT_ID']
        Digitalocean.api_key = ENV['DIGITAL_OCEAN_API_KEY']
      end
    end
  end
end
