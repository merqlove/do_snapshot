# -*- encoding : utf-8 -*-
require 'thor'
require 'do_snapshot'
require 'do_snapshot/command'
require 'do_snapshot/mail'
require 'do_snapshot/log'

module DoSnapshot
  # CLI is here
  #
  class CLI < Thor # rubocop:disable ClassLength
    default_task :snap

    map %w( c s create )  => :snap
    map %w( -V ) => :version

    # Overriding Thor method for custom initialization
    #
    def initialize(*args)
      super

      set_logger
      set_mailer

      # Check for keys via options
      %w( digital_ocean_client_id digital_ocean_api_key ).each do |key|
        ENV[key.upcase] = options[key] if options.include? key
      end

      try_keys_first
    end

    desc 'c / s / snap / create', 'DEFAULT. Create and cleanup snapshot\'s'
    long_desc <<-LONGDESC
    `do_snapshot` able to create and cleanup snapshots on your droplets.

    You can optionally specify parameters to select or exclude some droplets.

    ### Advanced options example for MAIL feature:

    --mail to:mail@somehost.com from:from@host.com --smtp address:smtp.gmail.com port:25 user_name:someuser password:somepassword

    For more details look here: https://github.com/benprew/pony

    ### Examples

    Keep latest 5 and cleanup older if maximum is reached:

    $ do_snapshot --keep 5 -c

    Keep latest 3 from selected droplets:

    $ do_snapshot --only 123456 1234567 --keep 3

    Working with all except selected droplets:

    $ do_snapshot --exclude 123456 123457

    Keep latest 5 snapshots, not create new if we have more, send mail notification instead:

    $ do_snapshot --keep 10 --stop --mail to:yourmail@example.com

    ### Cron example

    0 4 * * 7 /.../bin/do_snapshot -k 5 -m to:TO from:FROM -t address:HOST user_name:LOGIN password:PASSWORD port:2525 -q -c

    VERSION: #{DoSnapshot::VERSION}
    LONGDESC
    method_option :only,
                  type: :array,
                  default: [],
                  aliases: %w( -o ),
                  banner: '123456 123456 123456',
                  desc: 'Select some droplets.'
    method_option :exclude,
                  type: :array,
                  default: [],
                  aliases: %w( -e ),
                  banner: '123456 123456 123456',
                  desc: 'Except some droplets.'
    method_option :keep,
                  type: :numeric,
                  default: 10,
                  aliases: %w( -k ),
                  banner: '5',
                  desc: 'How much snapshots you want to keep?'
    method_option :delay,
                  type: :numeric,
                  default: 10,
                  aliases: %w( -d ),
                  banner: '5',
                  desc: 'Delay between snapshot operation status requests.'
    method_option :timeout,
                  type: :numeric,
                  default: 180,
                  banner: '250',
                  desc: 'Timeout in sec\'s for events like Power Off or Create Snapshot.'
    method_option :mail,
                  type: :hash,
                  aliases: %w( -m ),
                  banner: 'to:yourmail@example.com',
                  desc: 'Receive mail if fail or maximum is reached.'
    method_option :smtp,
                  type: :hash,
                  aliases: %w( -t ),
                  banner: 'user_name:yourmail@example.com password:password',
                  desc: 'SMTP options.'
    method_option :log,
                  type: :string,
                  aliases: %w( -l ),
                  banner: '/Users/someone/.do_snapshot/main.log',
                  desc: 'Log file path. By default logging is disabled.'
    method_option :clean,
                  type: :boolean,
                  aliases: %w( -c ),
                  desc: 'Cleanup snapshots after create. If you have more images than you want to `keep`, older will be deleted.'
    method_option :stop,
                  type: :boolean,
                  aliases: %w( -s),
                  desc: 'Stop creating snapshots if maximum is reached.'
    method_option :trace,
                  type: :boolean,
                  aliases: %w( -v ),
                  desc: 'Verbose mode.'
    method_option :quiet,
                  type: :boolean,
                  aliases: %w( -q ),
                  desc: 'Quiet mode. If don\'t need any messages and in console.'

    method_option :digital_ocean_client_id,
                  type: :string,
                  banner: 'YOURLONGAPICLIENTID',
                  desc: 'DIGITAL_OCEAN_CLIENT_ID. if you can\'t use environment.'
    method_option :digital_ocean_api_key,
                  type: :string,
                  banner: 'YOURLONGAPIKEY',
                  desc: 'DIGITAL_OCEAN_API_KEY. if you can\'t use environment.'

    def snap
      Command.snap options, %w( log trace digital_ocean_client_id digital_ocean_api_key )
    rescue => e
      Command.fail_power_off(e) if [SnapshotCreateError, DropletShutdownError].include?(e.class)
      Log.error e.message
      backtrace(e) if options.include? 'trace'
      if Mail.opts
        Mail.opts[:subject] = 'Digital Ocean: Error.'
        Mail.opts[:body] = 'Please check your droplets.'
        Mail.notify
      end
    end

    desc 'version, -V', 'Shows the version of the currently installed DoSnapshot gem'
    def version
      puts DoSnapshot::VERSION
    end

    no_commands do
      def set_mailer
        Mail.opts = options['mail']
        Mail.smtp = options['smtp']
      end

      def set_logger
        Log.quiet = options['quiet']
        Log.verbose = options['trace']
        # Use Thor shell
        Log.shell = shell unless options['quiet']
        init_logger if options.include?('log')
      end

      def init_logger
        Log.logger = Logger.new(options['log'])
        Log.logger.level = Log.verbose ? Logger::DEBUG : Logger::INFO
      end

      def backtrace(e)
        e.backtrace.each do |t|
          Log.error t
        end
      end

      # Check for DigitalOcean API keys
      def try_keys_first
        Log.debug 'Checking DigitalOcean Id\'s.'
        %w( DIGITAL_OCEAN_CLIENT_ID DIGITAL_OCEAN_API_KEY ).each do |key|
          Log.fail Thor::Error, "You must have #{key} in environment or set it via options." if !ENV[key] || ENV[key].empty?
        end
      end
    end
  end
end
