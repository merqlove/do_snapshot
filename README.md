# DoSnapshot

You can use this gem to backup's DigitalOcean droplet's via snapshot.

Here some features:

- Multiple threads out of the box.
- Binary for cron and command-line.
- Mail notification when maximum of snapshots for droplet reached.
- Custom mail settings (You can set [Pony](https://github.com/benprew/pony) mail settings).
- Stop mode (when you don't want to create new snapshots when maximum is reached).
- Logging into selected directory.
- Trace mode for research.
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
 

    $ export DIGITAL_OCEAN_CLIENT_ID = "SOMEID"
    $ export DIGITAL_OCEAN_API_KEY = "SOMEKEY"

 
If you want to set keys without environment, than set it via options:

    $ do_snapshot --digital-ocean-client-id YOURLONGAPICLIENTID --digital-ocean-api-key YOURLONGAPIKEY

E-mail notifications disabled out of the box. 
For working mailer you need to set e-mail settings via run options.

```shell
Usage:
  do_snapshot create

Options:
  -o, [--only=123456 123456 123456]                              # Use only selected droplets.
  -e, [--exclude=123456 123456 123456]                           # Except some droplets.
  -k, [--keep=5]                                                 # How much snapshots you want to keep?
                                                                 # Default: 10
  -s, [--stop], [--no-stop]                                      # Stop creating snapshots if maximum is reached.
  -m, [--mail=to:yourmail@example.com]                           # Receive mail if maximum is reached.
  -t, [--smtp=user_name:yourmail@example.com password:password]  # SMTP options.
  -l, [--log=/Users/someone/.do_snapshot/main.log]               # Log file path. By default logging is disabled.
  -d, [--trace], [--no-trace]                                    # Debug mode.
  -q, [--quiet], [--no-quiet]                                    # Quiet mode. If don't need any messages and log's
      [--digital-ocean-client-id=YOURLONGAPICLIENTID]            # DIGITAL_OCEAN_CLIENT_ID. if you can't use environment.
      [--digital-ocean-api-key=YOURLONGAPIKEY]                   # DIGITAL_OCEAN_API_KEY. if you can't use environment.

Description:
  `do_snapshot create` will create and cleanup snapshots on your droplets.

  You can optionally specify parameters to select or exclude some droplets.

  Advanced options example for MAIL feature:

  --mail to:mail@somehost.com from:from@host.com 
  --smtp address:smtp.gmail.com user_name:someuser password:somepassword

  For more details look here: [https://github.com/benprew/pony](https://github.com/benprew/pony)

  Example:

  > $ do_snapshot --keep 5 --quiet

  > $ do_snapshot --only 123456 1234567 --store 3

  > $ do_snapshot --exclude 123456 123457

  > $ do_snapshot --keep 10 --stop true --mail to:yourmail@example.com
```

## Contributing

1. Fork it ( https://github.com/[my-github-username]/do_snapshot/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
