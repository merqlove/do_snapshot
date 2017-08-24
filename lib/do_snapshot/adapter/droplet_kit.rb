# -*- encoding : utf-8 -*-
# frozen_string_literal: true

require_relative '../gem_ext/resource_kit'
require 'droplet_kit' unless defined?(::DropletKit)

module DoSnapshot
  module Adapter
    # API for CLI commands
    # Operating with Digital Ocean.
    #
    class DropletKit < Abstract
      attr_reader :client, :per_page, :page

      def initialize(*args)
        @per_page = 1000
        @page = 1
        super(*args)
      end

      # Get single droplet from DigitalOcean
      #
      def droplet(id)
        # noinspection RubyResolve
        result = client.droplets.find(id: id)
        fail DropletFindError, id unless result
        result
      rescue ::DropletKit::Error => e
        raise DropletFindError, id unless e.message
      end

      # Get droplets list from DigitalOcean
      #
      def droplets
        # noinspection RubyResolve
        response = client.droplets.all(page: page, per_page: per_page)
        response.many?
        response
      rescue ::NoMethodError => e
        fail DropletListError, e
      end

      def snapshots(instance)
        instance.snapshot_ids if instance.respond_to?(:snapshot_ids)
      end

      # Request Power On for droplet
      #
      def power_on(id)
        # noinspection RubyResolve
        response = client.droplet_actions.power_on(droplet_id: id)

        if response.status.include?('in-progress')
          logger.info "Droplet id: #{id} is requested for Power On."
        else
          logger.error "Droplet id: #{id} is failed to request for Power On."
        end
      rescue ::DropletKit::Error => e
        fail DoSnapshot::EventError.new(id), e.message
      end

      # Power Off request for Droplet
      #
      def stop_droplet(id)
        # noinspection RubyResolve,RubyResolve
        response = client.droplet_actions.power_off(droplet_id: id)

        # noinspection RubyResolve
        wait_shutdown(id, response.id)
      rescue ::DropletKit::Error => e
        fail DropletShutdownError.new(id), e.message
      end

      # Sending event to create snapshot via DigitalOcean API and wait for success
      #
      def create_snapshot(id, name)
        # noinspection RubyResolve,RubyResolve
        response = client.droplet_actions.snapshot(droplet_id: id, name: name)

        # noinspection RubyResolve
        wait_event(response.id)
      rescue ::DropletKit::Error => e
        fail DoSnapshot::SnapshotCreateError.new(id), e.message
      end

      # Checking if droplet is powered off.
      #
      def inactive?(id)
        instance = droplet(id)

        instance.status.include?('off') if instance.respond_to?(:status)
      end

      # Cleanup our snapshots.
      #
      def cleanup_snapshots(instance, size)
        (0..size).each do |i|
          # noinspection RubyResolve
          snapshot = snapshots(instance)[i]
          delete_image(instance, snapshot)
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
        @client = ::DropletKit::Client.new(access_token: ENV['DIGITAL_OCEAN_ACCESS_TOKEN'])
      end

      protected

      def delete_image(instance, snapshot) # rubocop:disable Metrics/AbcSize
        action = client.images.delete(id: snapshot)
        after_cleanup(instance.id, instance.name, snapshot, action)
      rescue ::DropletKit::Error => e
        logger.debug "#{snapshot} #{e.message}"
        after_cleanup(instance.id, instance.name, snapshot, false)
      end

      def after_cleanup(droplet_id, droplet_name, snapshot, action)
        if !action
          logger.error "Destroy of snapshot #{snapshot} for droplet id: #{droplet_id} name: #{droplet_name} is failed."
        else
          logger.debug "Snapshot: #{snapshot} delete requested."
        end
      end

      # Looking for event status.
      #
      def get_event_status(id, time)
        return true if timeout?(id, time)

        response = client.actions.find(id: id)

        fail DoSnapshot::EventError.new(id), response.message unless response.respond_to?(:status)

        # noinspection RubyResolve,RubyResolve
        response.status.include?('completed') ? true : false
      end
    end
  end
end
