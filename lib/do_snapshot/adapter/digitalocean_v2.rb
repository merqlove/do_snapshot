# -*- encoding : utf-8 -*-
require 'droplet_kit' unless defined?(::DropletKit)

module DoSnapshot
  module Adapter
    # API for CLI commands
    # Operating with Digital Ocean.
    #
    class DigitaloceanV2 < Abstract
      attr_reader :client

      # Get single droplet from DigitalOcean
      #
      def droplet(id)
        # noinspection RubyResolve
        response = client.droplets.find(id: id)
        fail DropletFindError unless response
        response
      rescue => e
        raise DropletFindError, e.message
      end

      # Get droplets list from DigitalOcean
      #
      def droplets
        # noinspection RubyResolve
        response = client.droplets.all
        fail DropletListError unless response
        response.each
      rescue => e
        raise DropletListError, e.message
      end

      def snapshots(instance)
        instance.snapshot_ids
      end

      # Power On request for Droplet
      #
      def start_droplet(id)
        # noinspection RubyResolve
        instance = droplet(id)

        return power_on(id) unless instance.status && instance.status.include?('active')

        logger.error "Droplet #{id} is still running. Skipping."
      end

      # Power Off request for Droplet
      #
      def stop_droplet(id)
        # noinspection RubyResolve,RubyResolve
        event = client.droplet_actions.power_off(droplet_id: id)

        # noinspection RubyResolve
        wait_event(event.id)
      rescue => e
        raise DropletShutdownError.new(id), e.message, e.backtrace
      end

      # Sending event to create snapshot via DigitalOcean API and wait for success
      #
      def create_snapshot(id, name)
        # noinspection RubyResolve,RubyResolve
        event = client.droplet_actions.snapshot(droplet_id: id, name: name)

        fail DoSnapshot::SnapshotCreateError.new(id) unless event && event.respond_to?(:id)

        # noinspection RubyResolve
        wait_event(event.id)
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
          snapshot = instance.snapshot_ids[i]
          event = client.images.delete(id: snapshot)

          unless event.is_a?(TrueClass)
            logger.debug event
            event = false
          end

          after_cleanup(instance.id, instance.name, snapshot, event)
        end
      end

      def check_keys
        logger.debug 'Checking DigitalOcean Access Token.'
        %w( DIGITAL_OCEAN_ACCESS_TOKEN ).each do |key|
          fail DoSnapshot::NoTokenError, "You must have #{key} in environment or set it via options." if ENV[key].blank?
        end
      end

      # Set id's of Digital Ocean API.
      #
      def set_id
        logger.debug 'Setting DigitalOcean Access Token.'
        @client = ::DropletKit::Client.new(access_token: ENV['DIGITAL_OCEAN_ACCESS_TOKEN'])
      end

      protected

      def after_cleanup(droplet_id, droplet_name, snapshot, event)
        if !event
          logger.error "Destroy of snapshot #{snapshot} for droplet id: #{droplet_id} name: #{droplet_name} is failed."
        else
          logger.debug "Snapshot: #{snapshot} delete requested."
        end
      end

      # Looking for event status.
      # Before snapshot we to know that machine has powered off.
      #
      def get_event_status(id, time)
        return true if timeout?(id, time)

        action = client.actions.find(id: id)

        fail DoSnapshot::EventError.new(id) unless action && action.respond_to?(:status)

        # noinspection RubyResolve,RubyResolve
        action.status.include?('completed') ? true : false
      end

      # Request Power On for droplet
      #
      def power_on(id)
        # noinspection RubyResolve
        event = client.droplet_actions.power_on(droplet_id: id)
        if event.status.include?('in-progress')
          logger.info 'Power On has been requested.'
        else
          logger.error 'Power On failed to request.'
        end
      end
    end
  end
end
