require 'do_snapshot/version'
require 'logger'

# Used primary for creating snapshot's as backups for DigitalOcean
#
module DoSnapshot
  # Shared logger
  #
  class Log
    class << self
      attr_accessor :logger
      attr_accessor :thor_log

      def log(type, message)
        logger.send(type, message) if logger
      end

      def info(message)
        log :info, message
        say message, :green
      end

      def warning(message)
        log :warn, message
        say message, :yellow
      end

      def error(message)
        log :error, message
        say message, :red
      end

      def debug(message)
        log :debug, message
        say message, :white if logger && logger.level == Logger::DEBUG
      end

      protected

      def say(message, color)
        thor_log.say message, color if thor_log
      end
    end
  end
end
