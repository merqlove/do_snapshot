require 'digitalocean'
require 'date'
require 'pony'
require 'core_ext/hash'
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

        self.notify  = false
        self.threads = []

        work_droplets
        email_message if notify && mail

        Log.info 'All snapshots requested'
      end

      protected

      attr_accessor :droplets
      attr_accessor :exclude
      attr_accessor :only
      attr_accessor :keep
      attr_accessor :mail
      attr_accessor :smtp
      attr_accessor :stop
      attr_accessor :notify
      attr_accessor :threads

      # Getting droplets list from API.
      # And store into object.
      #
      def load_droplets
        set_id
        Log.debug 'Loading list of DigitalOcean droplets'
        droplets = Digitalocean::Droplet.all
        fail droplets.message unless droplets.status == 'OK'
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
          fail instance.message unless instance.status == 'OK'

          prepare_instance instance.droplet
        end
        thread_chain
      end

      # Threads review
      #
      def thread_chain
        threads.each {|t| t.join}
      end

      # Preparing instance to take snapshot.
      # Instance must be powered off first!
      #
      def prepare_instance(instance)
        return unless instance
        Log.debug "Preparing droplet id: #{instance.id} name: #{instance.name} to snapshot."

        warning_size = "For droplet with id: #{instance.id} and name: #{instance.name} the maximum #{keep} is reached."

        if instance.snapshots.size >= keep && stop
          Log.warning warning_size
          self.notify = true
          return
        end

        # Stopping instance.
        Log.debug 'Shutting down droplet.'
        threads << Thread.new do
          unless instance.status.include? 'off'
            event = Digitalocean::Droplet.power_off(instance.id)
            if event.status.include? 'OK'
              sleep 1.3 until get_event_status(event.event_id)
            end
          end

          # Create snapshot.
          create_snapshot instance, warning_size
        end
      end

      # Trying to create a snapshot.
      #
      def create_snapshot(instance, warning_size)
        Log.debug "Start creating snapshot for droplet id: #{instance.id} name: #{instance.name}."

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

        sleep 10 until get_event_status(event.event_id)

        snapshot_size += 1

        Log.info "Snapshot name: #{name} created successfully."
        Log.info "Droplet id: #{instance.id} name: #{instance.name} snapshots: #{snapshot_size}."

        if snapshot_size > keep
          Log.warning warning_size if snapshot_size > keep
          self.notify = true
        end
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

      # Sending message via Hash params.
      #
      # Options:: -m to:mail@somehost.com from:from@host.com -t address:smtp.gmail.com user_name:someuser password:somepassword
      #
      def email_message
        mail.symbolize_keys!
        smtp.symbolize_keys!

        mail[:subject] = 'DigitalOcean Snapshot maximum is reached.' unless mail[:subject]
        mail[:body] = "Please cleanup your Digital Ocean account. \nSnapshot maximum is reached." unless mail[:body]
        mail[:from] = 'noreply@someonelse.com' unless mail[:from]
        mail[:via] = :smtp unless mail[:via]

        smtp[:domain] = 'localhost.localdomain' unless smtp[:domain]
        smtp[:port] = '25' unless smtp[:port]

        mail[:via_options] = smtp

        Log.debug 'Sending e-mail notification.'
        # Look into your inbox :)
        Pony.mail(mail)
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
