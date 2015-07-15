# -*- encoding : utf-8 -*-

module DoSnapshot
  module Adapter
    # API for CLI commands
    # Operating with Digital Ocean.
    #
    class Abstract
      include DoSnapshot::Log

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
        log.debug "Event Id: #{id}"
        time = Time.now
        sleep(delay) until get_event_status(id, time)
      end

      def after_cleanup(droplet_id, droplet_name, snapshot, event)
        if !event
          log.error "Destroy of snapshot #{snapshot.name} for droplet id: #{droplet_id} name: #{droplet_name} is failed."
        elsif event && !event.status.include?('OK')
          log.error event.message
        else
          log.debug "Snapshot name: #{snapshot.name} delete requested."
        end
      end
    end
  end
end
