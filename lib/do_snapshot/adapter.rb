require_relative 'adapter/abstract'

require_relative 'adapter/digitalocean'
require_relative 'adapter/digitalocean_v2'

module DoSnapshot
  # Adapter interface for API connections
  # Ability to select DigitalOcean API versions.
  #
  module Adapter
    def api(protocol, options)
      case protocol
      when 1
        return Digitalocean.new(options)
      else
        return DigitaloceanV2.new(options)
      end
    end
    module_function :api
  end
end
