require_relative 'adapter/abstract'

require_relative 'adapter/digitalocean_v2'

module DoSnapshot
  # Adapter interface for API connections
  # Ability to select DigitalOcean API versions.
  #
  module Adapter
    class << self
      def api(protocol, options = {})
        konst = find_protocol(protocol)
        fail DoSnapshot::NoProtocolError, "Not existing protocol: #{protocol}." unless
            Object.const_defined?(konst)
        obj = Object.const_get(konst)
        obj.new(options)
      end

      private

      def find_protocol(protocol)
        if protocol.is_a?(Integer)
          "DoSnapshot::Adapter::DigitaloceanV#{protocol}"
        elsif protocol.is_a?(String)
          protocol
        else
          'DoSnapshot::Adapter::DigitaloceanV2'
        end
      end
    end
  end
end
