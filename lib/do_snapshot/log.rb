# -*- encoding : utf-8 -*-
require 'logger'

module DoSnapshot
  # Shared logger
  #
  class Log
    class << self
      attr_accessor :logger, :shell, :quiet, :verbose
      attr_writer :buffer

      def buffer
        @buffer ||= %w()
      end

      def info(message)
        log :info, message
      end

      def warning(message)
        log :warn, message
      end

      def error(message)
        log :error, message
      end

      def debug(message)
        log :debug, message
      end

      protected

      def log(type, message)
        buffer << message
        logger.send(type, message) if logger

        say message, color(type) unless type == :debug && !verbose
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
