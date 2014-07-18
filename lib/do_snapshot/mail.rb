require 'date'
require 'pony'
require 'do_snapshot/core_ext/hash'

module DoSnapshot
  # Shared mailer.
  #
  class Mail
    class << self
      attr_accessor :opts
      attr_writer :smtp

      def smtp
        @smtp ||= {}
      end

      # Sending message via Hash params.
      #
      # Options:: --mail to:mail@somehost.com from:from@host.com --smtp address:smtp.gmail.com user_name:someuser password:somepassword
      #
      def notify
        return unless opts

        opts.symbolize_keys!
        smtp.symbolize_keys!

        opts_setup
        smtp_setup

        Log.debug 'Sending e-mail notification.'
        # Look into your inbox :)
        Pony.mail(opts)
      end

      protected

      def opts_setup
        opts[:subject] = 'Digital Ocean: maximum snapshots is reached.' unless opts[:subject]
        opts[:body]    = "Please cleanup your Digital Ocean account.\nSnapshot maximum is reached." unless opts[:body]
        opts[:from]    = 'noreply@someonelse.com' unless opts[:from]
        opts[:to]      = 'to@someonelse.com' unless opts[:to]
        opts[:via]     = :smtp unless opts[:via]
        opts[:body]    = "#{opts[:body]}\n\nTrace: #{DateTime.now}\n#{Log.buffer.join("\n")}"
      end

      def smtp_setup
        smtp[:domain]  = 'localhost.localdomain' unless smtp[:domain]
        smtp[:port]    = '25' unless smtp[:port]
        opts[:via_options] = smtp
      end
    end
  end
end
