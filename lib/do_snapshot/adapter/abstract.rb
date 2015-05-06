# -*- encoding : utf-8 -*-

module DoSnapshot
  module Adapter
    # API for CLI commands
    # Operating with Digital Ocean.
    #
    class Abstract
      attr_accessor :delay
      attr_accessor :timeout

      def initialize(options)
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
        Log.debug "Event Id: #{id}"
        time = Time.now
        sleep(delay) until get_event_status(id, time)
      end

      def after_cleanup(droplet_id, droplet_name, snapshot, event)
        if !event
          Log.error "Destroy of snapshot #{snapshot.name} for droplet id: #{droplet_id} name: #{droplet_name} is failed."
        elsif event && !event.status.include?('OK')
          Log.error event.message
        else
          Log.debug "Snapshot name: #{snapshot.name} delete requested."
        end
      end
    end
  end
end
