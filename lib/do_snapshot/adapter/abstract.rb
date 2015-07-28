# -*- encoding : utf-8 -*-

module DoSnapshot
  module Adapter
    # API for CLI commands
    # Operating with Digital Ocean.
    #
    class Abstract
      include DoSnapshot::Helpers

      attr_accessor :delay, :timeout

      def initialize(options = {})
        check_keys
        set_id
        options.each_pair do |key, option|
          send("#{key}=", option)
        end
      end

      protected

      def set_id; end

      def check_keys; end

      # Waiting for event exit
      def wait_event(id)
        logger.debug "Event Id: #{id}"
        time = Time.now
        sleep(delay) until get_event_status(id, time)
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

      def timeout?(id, time)
        return false unless (Time.now - time) > @timeout
        logger.debug "Event #{id} finished by timeout #{time}"
        true
      end
    end
  end
end
