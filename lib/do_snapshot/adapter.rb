module DoSnapshot
  # Adapter interface for API connections
  # Ability to select DigitalOcean API versions.
  #
  module Adapter
    autoload :Abstract, 'do_snapshot/adapter/abstract'
    autoload :Barge, 'do_snapshot/adapter/barge'
    autoload :DropletKit, 'do_snapshot/adapter/droplet_kit'

    class << self
      def api(protocol, options = {})
        konst = find_protocol(protocol)
        fail DoSnapshot::NoProtocolError, "Not existing protocol: #{protocol}." unless
            DoSnapshot::Adapter.const_defined?(konst)
        obj = DoSnapshot::Adapter.const_get(konst)
        obj.new(options)
      end

      private

      def find_protocol(protocol)
        if protocol.is_a?(String)
          protocol
        else
          'Barge'
        end
      end
    end
  end
end
