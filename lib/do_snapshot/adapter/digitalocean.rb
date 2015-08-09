# -*- encoding : utf-8 -*-
require 'digitalocean_c' unless defined?(::DigitaloceanC)

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
        fail DropletFindError.new(id), response.message unless response.status.include? 'OK'
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

      # Request Power On for droplet
      #
      def power_on(id)
        # noinspection RubyResolve
        event = ::DigitaloceanC::Droplet.power_on(id)
        case event && event.status
        when 'OK'
          logger.info "Droplet id: #{id} is requested for Power On."
        else
          logger.error "Droplet id: #{id} is failed to request for Power On."
        end
      end

      # Power Off request for Droplet
      #
      def stop_droplet(id)
        # noinspection RubyResolve,RubyResolve
        event = ::DigitaloceanC::Droplet.power_off(id)

        fail event.message unless event.status.include? 'OK'

        # noinspection RubyResolve
        wait_shutdown(id, event.event_id)
      rescue => e
        raise DropletShutdownError.new(id), e.message, e.backtrace
      end

      # Sending event to create snapshot via DigitalOcean API and wait for success
      #
      def create_snapshot(id, name)
        # noinspection RubyResolve,RubyResolve
        event = ::DigitaloceanC::Droplet.snapshot(id, name: name)

        if !event
          fail DoSnapshot::SnapshotCreateError.new(id), 'Something wrong with DigitalOcean or with your connection :)'
        elsif event && !event.status.include?('OK')
          fail DoSnapshot::SnapshotCreateError.new(id), event.message
        end

        # noinspection RubyResolve
        wait_event(event.event_id)
      end

      # Checking if droplet is powered off.
      #
      def inactive?(id)
        instance = droplet(id)

        instance.status.include?('off')
      end

      # Cleanup our snapshots.
      #
      def cleanup_snapshots(instance, size)
        (0..size).each do |i|
          # noinspection RubyResolve
          snapshot = instance.snapshots[i]
          event = ::DigitaloceanC::Image.destroy(snapshot.id)

          after_cleanup(instance.id, instance.name, snapshot, event)
        end
      end

      def check_keys
        logger.debug 'Checking DigitalOcean Id\'s.'
        errors = %w( DIGITAL_OCEAN_CLIENT_ID DIGITAL_OCEAN_API_KEY ).map { |key| key if ENV[key].blank? }.compact
        fail DoSnapshot::NoKeysError, "You must have #{errors.join(', ')} in environment or set it via options." if errors.size > 0
      end

      protected

      # Set id's of Digital Ocean API.
      #
      def set_id
        logger.debug 'Setting DigitalOcean Id\'s.'
        ::DigitaloceanC.client_id = ENV['DIGITAL_OCEAN_CLIENT_ID']
        ::DigitaloceanC.api_key = ENV['DIGITAL_OCEAN_API_KEY']
      end

      # Looking for event status.
      #
      def get_event_status(id, time)
        return true if timeout?(id, time)

        event = ::DigitaloceanC::Event.find(id)
        fail DoSnapshot::EventError.new(id), event.message unless event.status.include?('OK')
        # noinspection RubyResolve,RubyResolve
        event.event.percentage && event.event.percentage.include?('100') ? true : false
      end
    end
  end
end
