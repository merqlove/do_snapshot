require 'digitalocean'

module DoSnapshot
  # API for CLI commands
  # Operating with Digital Ocean.
  #
  class API
    attr_accessor :delay

    def initialize(delay)
      set_id
      self.delay = delay
    end

    def droplet(id)
      # noinspection RubyResolve
      instance = Digitalocean::Droplet.find(id)
      fail DropletFindError, instance.message unless instance.status.include? 'OK'
      instance
    end

    def droplets
      # noinspection RubyResolve
      droplets = Digitalocean::Droplet.all
      fail DropletListError, droplets.message unless droplets.status.include? 'OK'
      droplets
    end

    # Power On request for Droplet
    #
    def start_droplet(id)
      # noinspection RubyResolve
      instance = Digitalocean::Droplet.find(id)

      fail unless instance.status.include? 'OK'

      if instance.droplet.status.include? 'active'
        Log.error 'Droplet is still running.'
      else
        power_on id
      end
    end

    # Power Off request for Droplet
    #
    def stop_droplet(id)
      # noinspection RubyResolve,RubyResolve
      event = Digitalocean::Droplet.power_off(id)
      # noinspection RubyResolve
      wait_event(event.event_id) if event.status.include? 'OK'
    rescue => e
      raise DropletShutdownError.new(id), e.message, e.backtrace
    end

    # Sending event to create snapshot via DigitalOcean API and wait for success
    #
    def create_snapshot(id, name)
      # noinspection RubyResolve,RubyResolve
      event = Digitalocean::Droplet.snapshot(id, name: name)

      if !event
        fail 'Something wrong with DigitalOcean or with your connection :)'
      elsif event && !event.status.include?('OK')
        fail event.message
      end

      # noinspection RubyResolve
      wait_event(event.event_id)
    end

    # Cleanup our snapshots.
    #
    def cleanup_snapshots(instance, size)
      (0..size).each do |i|
        # noinspection RubyResolve
        snapshot = instance.snapshots[i]
        event = Digitalocean::Image.destroy(snapshot.id)

        if !event
          fail 'Something wrong with DigitalOcean or with your connection :)'
        elsif event && !event.status.include?('OK')
          fail event.message
        end

        Log.debug "Snapshot name: #{snapshot.name} delete requested."
      end
    end

    protected

    # Set id's of Digital Ocean API.
    #
    def set_id
      Log.debug 'Setting DigitalOcean Id\'s.'
      Digitalocean.client_id = ENV['DIGITAL_OCEAN_CLIENT_ID']
      Digitalocean.api_key = ENV['DIGITAL_OCEAN_API_KEY']
    end

    def wait_event(id)
      sleep delay until get_event_status(id)
    end

    # Looking for event status.
    # Before snapshot we to know that machine has powered off.
    #
    def get_event_status(id)
      event = Digitalocean::Event.find(id)
      fail event.message unless event.status.include?('OK')
      # noinspection RubyResolve,RubyResolve
      event.event.percentage && event.event.percentage.include?('100') ? true : false
    end

    def power_on(id)
      # noinspection RubyResolve
      event = Digitalocean::Droplet.power_on(id)
      case event && event.status
      when 'OK'
        Log.info 'Power On has been requested.'
      else
        Log.error 'Power On failed to request.'
      end
    end
  end
end
