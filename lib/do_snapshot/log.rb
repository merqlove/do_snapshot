# -*- encoding : utf-8 -*-
require 'logger'

module DoSnapshot
  # Shared logger
  #
  module Log
    def log
      UniversalLogger
    end

    # UniversalLogger is module to deal with singleton methods.
    # Used to give classes access only for selected methods
    #
    module UniversalLogger
      %i(info warn error debug).each do |type|
        define_singleton_method(type) { |message| Log.log type, message }
      end
    end

    class << self
      attr_accessor :logger, :shell, :quiet, :verbose
      attr_writer   :buffer

      def load_options(options = {})
        options.each { |key, option| send("#{key}=", option) }
      end

      def buffer
        @buffer ||= %w()
      end

      def log(type, message)
        buffer << message
        logger.send(type, message) if logger

        say message, color(type) unless print?(type)
      end

      protected

      def print?(type)
        (type == :debug && !verbose) || quiet
      end

      def say(message, color)
        shell.say message, color if shell
      end

      def color(type)
        case type
        when :debug
          :white
        when :error
          :red
        when :warn
          :yellow
        else
          :green
        end
      end
    end
  end
end
