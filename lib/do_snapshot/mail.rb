# -*- encoding : utf-8 -*-
require 'date'
require 'pony'
require_relative 'core_ext/hash'

module DoSnapshot
  # Shared mailer.
  #
  class Mail
    class << self
      attr_accessor :opts
      attr_writer :smtp, :opts_default, :smtp_default

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

      def opts_default
        @opts_default ||= {
          subject: 'Digital Ocean: maximum snapshots is reached.',
          body: "Please cleanup your Digital Ocean account.\nSnapshot maximum is reached.",
          from: 'noreply@someonelse.com',
          to: 'to@someonelse.com',
          via: :smtp
        }
      end

      def smtp_default
        @smtp_default ||= {
          domain: 'localhost.localdomain',
          port: '25'
        }
      end

      def opts_setup
        opts_default.each_pair do |key, value|
          opts[key] = value unless opts.include? key
        end
        opts[:body]    = "#{opts[:body]}\n\nTrace: #{DateTime.now}\n#{Log.buffer.join("\n")}"
      end

      def smtp_setup
        smtp_default.each_pair do |key, value|
          smtp[key] = value unless smtp.include? key
        end
        opts[:via_options] = smtp
      end
    end
  end
end
