# DoSnapshot

You can use this gem to backup's DigitalOcean droplet's via snapshot method.

Here some features:

- Multiple threads out of the box. No matter how much droplet's you have.
- Auto-cleanup for old snapshots.
- Binary special for cron and command-line.
- Mail notifications when fail or maximum of snapshots is reached for one or multiple droplets.
- Custom mail settings (You can set [Pony](https://github.com/benprew/pony) mail settings).
- Stop mode (when you don't want to create new snapshots when maximum is reached).
- Logging into selected directory.
- Verbose mode for research.
- Quiet mode for silence.

There not so much of dependencies:

- `Digitalocean` for API requests.
- `Thor` for CLI.
- `Pony` for mail notifications.

## Installation

Add this line to your application's Gemfile:

    gem 'do_snapshot'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install do_snapshot

## Usage

First you may need to set DigitalOcean API keys: 

    $ export DIGITAL_OCEAN_CLIENT_ID="SOMEID"
    $ export DIGITAL_OCEAN_API_KEY="SOMEKEY"
 
If you want to set keys without environment, than set it via options when you run do_snapshot:

    $ do_snapshot --digital-ocean-client-id YOURLONGAPICLIENTID --digital-ocean-api-key YOURLONGAPIKEY

#### Basic usage
 
Here we `keeping` only 5 **latest** snapshots and cleanup older after new one is created. If creation of snapshots failed no one will be deleted. By default we keeping `10` droplets.

    $ do_snapshot --keep 5 -c
  
Keep latest 3 from selected droplets:
  
    $ do_snapshot --only 123456 1234567 --keep 3
  
Working with all except selected droplets:
  
    $ do_snapshot --exclude 123456 123457
  
Keep latest 5 snapshots, send mail notification instead of creating new one:
  
    $ do_snapshot --keep 10 --stop --mail to:yourmail@example.com
    
E-mail notifications disabled out of the box. 
For working mailer you need to set e-mail settings via run options.

    --mail to:mail@somehost.com from:from@host.com --smtp address:smtp.gmail.com port:25 user_name:someuser password:somepassword

#### Cron example

    0 4 * * 7 /.../bin/do_snapshot -k 5 -m to:TO from:FROM -t address:HOST user_name:LOGIN password:PASSWORD port:2525 -q -c

#### Real world example

    $ bin/do_snapshot --only 123456 -k 3 -c -m to:TO from:FROM -t address:HOST user_name:LOGIN password:PASSWORD port:2525 -v                                  
    
    Checking DigitalOcean Id's.
    Start performing operations
    Setting DigitalOcean Id's.
    Loading list of DigitalOcean droplets
    Working with list of DigitalOcean droplets
    Preparing droplet id: 123456 name: mrcr.ru to take snapshot.
    Shutting down droplet.
    Start creating snapshot for droplet id: 123456 name: mrcr.ru.
    Wait until snapshot will be created.
    Snapshot name: mrcr.ru_2014_07_18 created successfully.
    Droplet id: 123456 name: mrcr.ru snapshots: 4.
    For droplet with id: 123456 and name: mrcr.ru the maximum number 3 of snapshots is reached.
    Cleaning up snapshots for droplet id: 123456 name: mrcr.ru.
    Snapshot name: mrcr.ru_2014_07_17 delete requested.
    All operations has been finished.
    Sending e-mail notification.

### All options:    

    > $ do_snapshot c  
    
    aliases: s, snap, create
    
    Options:
      -o, [--only=123456 123456 123456]                              # Select some droplets.
      -e, [--exclude=123456 123456 123456]                           # Except some droplets.
      -k, [--keep=5]                                                 # How much snapshots you want to keep?
                                                                     # Default: 10
      -m, [--mail=to:yourmail@example.com]                           # Receive mail if fail or maximum is reached.
      -t, [--smtp=user_name:yourmail@example.com password:password]  # SMTP options.
      -l, [--log=/Users/someone/.do_snapshot/main.log]               # Log file path. By default logging is disabled.
      -c, [--clean], [--no-clean]                                    # Cleanup snapshots after create. If you have more images than you want to `keep`, older will be deleted.
      -s, [--stop], [--no-stop]                                      # Stop creating snapshots if maximum is reached.
      -v, [--trace], [--no-trace]                                    # Verbose mode.
      -q, [--quiet], [--no-quiet]                                    # Quiet mode. If don't need any messages in console.
          [--digital-ocean-client-id=YOURLONGAPICLIENTID]            # DIGITAL_OCEAN_CLIENT_ID. if you can't use environment.
          [--digital-ocean-api-key=YOURLONGAPIKEY]                   # DIGITAL_OCEAN_API_KEY. if you can't use environment.    
    
    Description:
      `do_snapshot` able to create and cleanup snapshots on your droplets.
    
      You can optionally specify parameters to select or exclude some droplets.   

## Contributing

1. Fork it ( https://github.com/merqlove/do_snapshot/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
