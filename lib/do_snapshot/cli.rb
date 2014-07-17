require 'do_snapshot'
require 'do_snapshot/command'

module DoSnapshot
  # CLI is here
  #
  class CLI < Thor
    default_task :snap

    map %w( c s create )  => :snap
    map %w( -V ) => :version

    def initialize(*args)
      super

      Log.quiet = options['quiet']
      # Use Thor shell
      Log.shell = shell unless Log.quiet
      Log.verbose = options['trace']

      logger if options.include?('log')

      Log.mail = options['mail']
      Log.smtp = options['smtp']

      # Check for keys via options
      ENV['DIGITAL_OCEAN_CLIENT_ID'] = options['digital_ocean_client_id'] if options.include? 'digital_ocean_client_id'
      ENV['DIGITAL_OCEAN_API_KEY']   = options['digital_ocean_api_key'] if options.include? 'digital_ocean_api_key'

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

    method_option :only,    type: :array,   default: [], aliases: %w( -o ), banner: '123456 123456 123456', desc: 'Select some droplets.'
    method_option :exclude, type: :array,   default: [], aliases: %w( -e ), banner: '123456 123456 123456', desc: 'Except some droplets.'
    method_option :keep,    type: :numeric, default: 10, aliases: %w( -k ), banner: '5', desc: 'How much snapshots you want to keep?'
    method_option :delay,   type: :numeric, default: 10, aliases: %w( -d ), banner: '5', desc: 'Delay between snapshot operation status requests.'
    method_option :mail,    type: :hash,    aliases: %w( -m ), banner: 'to:yourmail@example.com', desc: 'Receive mail if fail or maximum is reached.'
    method_option :smtp,    type: :hash,    aliases: %w( -t ), banner: 'user_name:yourmail@example.com password:password', desc: 'SMTP options.'
    method_option :log,     type: :string,  aliases: %w( -l ), banner: '/Users/someone/.do_snapshot/main.log', desc: 'Log file path. By default logging is disabled.'
    method_option :clean,   type: :boolean, aliases: %w( -c ), desc: 'Cleanup snapshots after create. If you have more images than you want to `keep`, older will be deleted.'
    method_option :stop,    type: :boolean, aliases: %w( -s),  desc: 'Stop creating snapshots if maximum is reached.'
    method_option :trace,   type: :boolean, aliases: %w( -v ), desc: 'Verbose mode.'
    method_option :quiet,   type: :boolean, aliases: %w( -q ), desc: 'Quiet mode. If don\'t need any messages and in console.'

    method_option :digital_ocean_client_id, type: :string, banner: 'YOURLONGAPICLIENTID', desc: 'DIGITAL_OCEAN_CLIENT_ID. if you can\'t use environment.'
    method_option :digital_ocean_api_key,   type: :string, banner: 'YOURLONGAPIKEY',      desc: 'DIGITAL_OCEAN_API_KEY. if you can\'t use environment.'

    def snap
      Command.execute options, %w( log trace digital_ocean_client_id digital_ocean_api_key )
    rescue => e

      Command.fail_power_on(e.id) if e && e.class == SnapshotCreateError && e.respond_to?('id')
      Log.error e.message
      backtrace(e) if options.include? 'trace'
      if Log.mail
        Log.mail[:subject] = 'Digital Ocean: Error.'
        Log.mail[:body] = 'Please check your droplets.'
        Log.notify
      end
    end

    desc 'version, -V', 'Shows the version of the currently installed DoSnapshot gem'
    def version
      puts DoSnapshot::VERSION
    end

    protected

    def logger
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
      fail Thor::Error, 'You must have DIGITAL_OCEAN_CLIENT_ID in environment or set via options.' if !ENV['DIGITAL_OCEAN_CLIENT_ID'] || ENV['DIGITAL_OCEAN_CLIENT_ID'].empty?
      fail Thor::Error, 'You must have DIGITAL_OCEAN_API_KEY in environment or set via options.' if !ENV['DIGITAL_OCEAN_API_KEY'] || ENV['DIGITAL_OCEAN_API_KEY'].empty?
    end
  end
end
