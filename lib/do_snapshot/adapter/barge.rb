# -*- encoding : utf-8 -*-
require 'barge' unless defined?(::Barge)
require 'active_support/core_ext/kernel/reporting'

module DoSnapshot
  module Adapter
    # API for CLI commands
    # Operating with Digital Ocean.
    #
    class Barge < Abstract
      attr_reader :client

      # Get single droplet from DigitalOcean
      #
      def droplet(id)
        silence_warnings do
          # noinspection RubyResolve
          response = client.droplet.show(id)
          fail DropletFindError.new(id), response.message unless response.respond_to?(:droplet)
          response.droplet
        end
      end

      # Get droplets list from DigitalOcean
      #
      def droplets
        # noinspection RubyResolve
        silence_warnings do
          response = client.droplet.all
          fail DropletListError, response.message unless response.respond_to?(:droplets)
          response.droplets
        end
      end

      def snapshots(instance)
        instance.snapshot_ids
      end

      # Request Power On for droplet
      #
      def power_on(id)
        silence_warnings do
          _power_on(id)
        end
      end

      # Power Off request for Droplet
      #
      def stop_droplet(id)
        silence_warnings do
          # noinspection RubyResolve,RubyResolve
          response = client.droplet.power_off(id)

          fail DropletShutdownError.new(id), response.message unless response.respond_to?(:action)

          # noinspection RubyResolve
          wait_shutdown(id, response.action.id)
        end
      end

      # Sending event to create snapshot via DigitalOcean API and wait for success
      #
      def create_snapshot(id, name)
        silence_warnings do
          # noinspection RubyResolve,RubyResolve
          response = client.droplet.snapshot(id, name: name)

          fail DoSnapshot::SnapshotCreateError.new(id), response.message unless response.respond_to?(:action)

          # noinspection RubyResolve
          wait_event(response.action.id)
        end
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
          action = client.image.destroy(snapshot)

          logger.debug action unless action.success?

          after_cleanup(instance.id, instance.name, snapshot, action)
        end
      end

      def check_keys
        logger.debug 'Checking DigitalOcean Access Token.'
        %w( DIGITAL_OCEAN_ACCESS_TOKEN ).each do |key|
          fail DoSnapshot::NoTokenError, "You must have #{key} in environment or set it via options." if ENV[key].nil? || ENV[key].empty?
        end
      end

      # Set id's of Digital Ocean API.
      #
      def set_id
        logger.debug 'Setting DigitalOcean Access Token.'
        @client = ::Barge::Client.new(access_token: ENV['DIGITAL_OCEAN_ACCESS_TOKEN'], timeout: 15, open_timeout: 15)
      end

      protected

      # Request Power On for droplet
      #
      def _power_on(id)
        # noinspection RubyResolve
        response = client.droplet.power_on(id)

        fail DoSnapshot::EventError.new(id), response.message unless response.respond_to?(:action)

        if response.action.status.include?('in-progress')
          logger.info "Droplet id: #{id} is requested for Power On."
        else
          logger.error "Droplet id: #{id} is failed to request for Power On."
        end
      end

      def after_cleanup(droplet_id, droplet_name, snapshot, action)
        if !action.success?
          logger.error "Destroy of snapshot #{snapshot} for droplet id: #{droplet_id} name: #{droplet_name} is failed."
        else
          logger.debug "Snapshot: #{snapshot} delete requested."
        end
      end

      # Looking for event status.
      #
      def get_event_status(id, time)
        return true if timeout?(id, time)

        response = client.action.show(id)

        fail DoSnapshot::EventError.new(id), response.message unless response.respond_to?(:action)

        # noinspection RubyResolve,RubyResolve
        response.action.status.include?('completed') ? true : false
      end
    end
  end
end
