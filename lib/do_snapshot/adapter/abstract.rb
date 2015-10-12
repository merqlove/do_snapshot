# -*- encoding : utf-8 -*-

module DoSnapshot
  module Adapter
    # API for CLI commands
    # Operating with Digital Ocean.
    #
    class Abstract
      include DoSnapshot::Helpers

      attr_accessor :delay, :timeout
      attr_writer   :stop_by

      def initialize(options = {})
        check_keys
        set_id
        options.each_pair do |key, option|
          send("#{key}=", option)
        end
      end

      # Power On request for Droplet
      #
      def start_droplet(id)
        # noinspection RubyResolve
        instance = droplet(id)

        return power_on(id) unless instance.status.include?('active')

        logger.error "Droplet #{id} is still running. Skipping."
      end

      protected

      def set_id; end

      def check_keys; end

      def stop_by
        @stop_by ||= :event_status
      end

      # Waiting wrapper
      def wait_wrap(id, message = "Event Id: #{id}", &status_block)
        logger.debug message
        time = Time.now
        sleep(delay) until status_block.call(id, time)
      rescue => e
        logger.error e.message
        e.backtrace.each { |t| logger.error t }
        DoSnapshot::EventError.new(id)
      end

      # Waiting for event exit
      def wait_event(event_id)
        wait_wrap(event_id) { |id, time| get_event_status(id, time) }
      end

      # Waiting for droplet shutdown
      def wait_shutdown(droplet_id, event_id)
        case stop_by
        when :power_status
          wait_wrap(droplet_id, "Droplet Id: #{droplet_id} shutting down") { |id, time| get_shutdown_status(id, time) }
        when :event_status
          wait_event(event_id)
        else
          fail 'Please define :stopper method (:droplet_status, :event_status'
        end
      end

      def after_cleanup(droplet_id, droplet_name, snapshot, event)
        if !event
          logger.error "Destroy of snapshot #{snapshot.name} for droplet id: #{droplet_id} name: #{droplet_name} is failed."
        elsif event && !event.status.include?('OK')
          logger.error event.message
        else
          logger.debug "Snapshot name: #{snapshot.name} delete requested."
        end
      end

      # Event request timeout.
      #
      def timeout?(id, time, message = "Event #{id} finished by timeout #{time}")
        return false unless (Time.now - time) > @timeout
        logger.debug message
        true
      end

      # Droplet request timeout
      #
      def droplet_timeout?(id, time)
        timeout? id, time, "Droplet id: #{id} shutdown event closed by timeout #{time}"
      end

      # This is stub for event status
      def get_event_status(_id, _time)
        true
      end

      # Looking for droplet status.
      # Before snapshot we need to know that machine is powered off.
      #
      def get_shutdown_status(id, time)
        fail "Droplet #{id} not responding for shutdown!" if droplet_timeout?(id, time)

        inactive?(id)
      end
    end
  end
end
