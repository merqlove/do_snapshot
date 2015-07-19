require_relative 'log'
require_relative 'mail'

module DoSnapshot
  module Helpers
    def logger
      UniversalLogger
    end

    # UniversalLogger is a module to deal with singleton methods.
    # Used to give classes access only for selected methods
    #
    module UniversalLogger
      module_function
      %w(debug info warn error fatal unknown).each do |name|
        define_method(:"#{name}") { |*args, &block| DoSnapshot.logger.send(:"#{name}", *args, &block) }
      end

      def close
        DoSnapshot.logger.close
      end
    end

    def mailer
      DoSnapshot.mailer
    end
  end
end