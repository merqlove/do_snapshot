# -*- encoding : utf-8 -*-
begin
  require 'digitalocean_c' unless defined?(::DigitaloceanC)
rescue LoadError
end

module DoSnapshot
  module Adapter
    # API for CLI commands
    # Operating with Digital Ocean.
    #
    class Digitalocean < Abstract
      # Get single droplet from DigitalOcean
      #
      def droplet(id)
        # noinspection RubyResolve
        response = ::DigitaloceanC::Droplet.find(id)
        fail DropletFindError, response.message unless response.status.include? 'OK'
        response.droplet
      end

      # Get droplets list from DigitalOcean
      #
      def droplets
        # noinspection RubyResolve
        response = ::DigitaloceanC::Droplet.all
        fail DropletListError, response.message unless response.status.include? 'OK'
        response.droplets
      end

      def snapshots(instance)
        instance.snapshots
      end

      # Power On request for Droplet
      #
      def start_droplet(id)
        # noinspection RubyResolve
        instance = droplet(id)

        if instance.status.include? 'active'
          Log.error 'Droplet is still running.'
        else
          power_on id
        end
      end

      # Power Off request for Droplet
      #
      def stop_droplet(id)
        # noinspection RubyResolve,RubyResolve
        event = ::DigitaloceanC::Droplet.power_off(id)

        fail event.message unless event.status.include? 'OK'

        # noinspection RubyResolve
        wait_event(event.event_id)
      rescue => e
        raise DropletShutdownError.new(id), e.message, e.backtrace
      end

      # Sending event to create snapshot via DigitalOcean API and wait for success
      #
      def create_snapshot(id, name)
        # noinspection RubyResolve,RubyResolve
        event = ::DigitaloceanC::Droplet.snapshot(id, name: name)

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
      def cleanup_snapshots(instance, size) # rubocop:disable MethodLength
        (0..size).each do |i|
          # noinspection RubyResolve
          snapshot = instance.snapshots[i]
          event = ::DigitaloceanC::Image.destroy(snapshot.id)

          after_cleanup(instance.id, instance.name, snapshot, event)
        end
      end

      def check_keys
        Log.debug 'Checking DigitalOcean Id\'s.'
        %w( DIGITAL_OCEAN_CLIENT_ID DIGITAL_OCEAN_API_KEY ).each do |key|
          Log.error "You must have #{key} in environment or set it via options." if ENV[key].blank?
        end
      end

      protected

      # Set id's of Digital Ocean API.
      #
      def set_id
        Log.debug 'Setting DigitalOcean Id\'s.'
        ::DigitaloceanC.client_id = ENV['DIGITAL_OCEAN_CLIENT_ID']
        ::DigitaloceanC.api_key = ENV['DIGITAL_OCEAN_API_KEY']
      end

      # Looking for event status.
      # Before snapshot we to know that machine has powered off.
      #
      def get_event_status(id, time)
        if (Time.now - time) > @timeout
          Log.debug "Event #{id} finished by timeout #{time}"
          return true
        end

        event = ::DigitaloceanC::Event.find(id)
        fail event.message unless event.status.include?('OK')
        # noinspection RubyResolve,RubyResolve
        event.event.percentage && event.event.percentage.include?('100') ? true : false
      end

      # Request Power On for droplet
      #
      def power_on(id)
        # noinspection RubyResolve
        event = ::DigitaloceanC::Droplet.power_on(id)
        case event && event.status
        when 'OK'
          Log.info 'Power On has been requested.'
        else
          Log.error 'Power On failed to request.'
        end
      end
    end
  end
end
