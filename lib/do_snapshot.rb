require 'do_snapshot/version'
require 'thor'
require 'logger'
require 'date'
require 'pony'
require 'do_snapshot/core_ext/hash'

# Used primary for creating snapshot's as backups for DigitalOcean
#
module DoSnapshot
  # Set multiple Errors with `id` @param
  #
  class DigitalOceanError < StandardError
    attr_reader :id
    # @param [Object] id
    def initialize(id)
      @id = id
    end
  end
  class DropletShutdownError < DigitalOceanError; end
  class SnapshotCreateError < DigitalOceanError; end
  class SnapshotCleanupError < DigitalOceanError; end

  # Shared logger
  #
  class Log
    class << self
      attr_accessor :logger
      attr_accessor :shell
      attr_accessor :mail
      attr_accessor :quiet
      attr_accessor :verbose
      attr_writer :smtp

      def smtp
        @smtp ||= {}
      end

      def log(type, message)
        buffer << message
        logger.send(type, message) if logger

        say message, color(type) unless type == :debug && !debug?
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

      def say(message, color)
        shell.say message, color if shell
      end

      def debug?
        logger && logger.level == Logger::DEBUG
      end

      # Sending message via Hash params.
      #
      # Options:: --mail to:mail@somehost.com from:from@host.com --smtp address:smtp.gmail.com user_name:someuser password:somepassword
      #
      def notify
        return unless mail

        mail.symbolize_keys!
        smtp.symbolize_keys!

        notify_init

        Log.debug 'Sending e-mail notification.'
        # Look into your inbox :)
        Pony.mail(mail)
      end

      protected

      def notify_init
        mail[:subject] = 'Digital Ocean: maximum snapshots is reached.' unless mail[:subject]
        mail[:body]    = "Please cleanup your Digital Ocean account.\nSnapshot maximum is reached." unless mail[:body]
        mail[:from]    = 'noreply@someonelse.com' unless mail[:from]
        mail[:to]      = 'to@someonelse.com' unless mail[:to]
        mail[:via]     = :smtp unless mail[:via]
        mail[:body]    = "#{mail[:body]}\n\nTrace: #{DateTime.now}\n#{buffer.join("\n")}"
        smtp[:domain]  = 'localhost.localdomain' unless smtp[:domain]
        smtp[:port]    = '25' unless smtp[:port]

        mail[:via_options] = smtp
      end

      attr_writer :buffer
      def buffer
        @buffer ||= %w()
      end
    end
  end
end
