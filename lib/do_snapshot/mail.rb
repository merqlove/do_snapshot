# -*- encoding : utf-8 -*-
require 'date'
require 'pony'
require_relative 'core_ext/hash'
require_relative 'helpers'

module DoSnapshot
  # Shared mailer.
  #
  class Mail
    include DoSnapshot::Helpers

    attr_writer :mailer, :opts_default, :smtp_default

    def initialize(options = {})
      options.each { |key, option| send("#{key}=", option) }
    end

    def reset_options
      @opts = opts_default
      @smtp = smtp_default
    end

    def mailer
      @mailer ||= Pony.method(:mail)
    end

    def smtp
      @smtp ||= smtp_default.dup
    end

    def opts
      @opts ||= opts_default.dup
    end

    def smtp=(options)
      options.each_pair do |key, value|
        smtp[key.to_sym] = value
      end if options
    end

    def opts=(options)
      options.each_pair do |key, value|
        opts[key.to_sym] = value
      end if options
    end

    # Sending message via Hash params.
    #
    # Options:: --mail to:mail@somehost.com from:from@host.com --smtp address:smtp.gmail.com user_name:someuser password:somepassword
    #
    def notify
      setup_notify
      logger.debug 'Sending e-mail notification.'
      # Look into your inbox :)
      mailer.call(opts)
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

    def setup_notify
      opts[:body] = "#{opts[:body]}\n\nTrace: #{DateTime.now}\n#{DoSnapshot.logger.buffer.join("\n")}"
      opts[:via_options] = smtp
    end
  end
end
