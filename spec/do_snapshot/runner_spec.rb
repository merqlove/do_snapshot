# -*- encoding : utf-8 -*-
require 'spec_helper'

RSpec.describe DoSnapshot::Runner, type: :aruba do
  include_context 'spec'

  context 'commands' do
    context '.snap' do
      RSpec.shared_examples '.snap methods' do
        it 'with error' do
          run 'do_snapshot snap --some-param=5'

          expect(all_stderr).to match(/ERROR: ".*" was called with arguments \["--some-param=5"\]/)
        end

        it 'with exclude' do
          excluded_droplets = %w( 100824 )
          stub_all_api(%w(100825 100823))
          hash_attribute_eq_no_stub(exclude: excluded_droplets, only: %w())

          expect(all_stdout).to be_found_n_times(t_snapshot_created(snapshot_name), 2)
          expect(all_stdout).not_to include('100824')
        end

        it 'with only' do
          selected_droplets = %w( 100823 )
          stub_all_api(selected_droplets)
          hash_attribute_eq_no_stub(only: selected_droplets)
          expect(last_command).to have_exit_status(0)

          expect(all_stdout).to be_found_n_times(t_snapshot_created(snapshot_name), 1)
          expect(all_stdout).not_to include('100825')
          expect(all_stdout).not_to include('100824')
        end

        it 'with 1 delay' do
          aruba.config.exit_timeout = 1

          hash_attribute_eq delay: 1, timeout: timeout
          expect(last_command).to have_exit_status(0)
          expect(last_command).to have_finished_in_time

          aruba.config.exit_timeout = 15
        end

        it 'with 0 delay' do
          hash_attribute_eq delay: 0, timeout: timeout

          expect(last_command).to have_exit_status(0)
        end

        it 'with custom timeout' do
          aruba.config.exit_timeout = 1

          hash_attribute_eq timeout: 1, delay: 2

          expect(last_command).to have_exit_status(0)
          expect(last_command).to have_finished_in_time

          aruba.config.exit_timeout = 15
        end

        it 'with keep' do
          attribute_eq 'keep', 7

          expect(last_command).to have_exit_status(0)
          expect(all_stdout).not_to include(t_is_reached)
          expect(all_stdout).not_to include(t_snapshots_cleaning(droplet_id))
        end

        it 'with no keep' do
          attribute_eq 'keep', 3

          expect(last_command).to have_exit_status(0)
          expect(all_stdout).to be_found_n_times(t_is_reached, 2)
          expect(all_stdout).to include(t_snapshots_cleaning(droplet_id))
        end

        it 'with quiet' do
          attribute_eq 'quiet', true

          expect(last_command).to have_exit_status(0)
          expect(all_stdout).to eq('')
        end

        it 'with no quiet' do
          attribute_eq 'quiet', false

          expect(last_command).to have_exit_status(0)
          expect(all_stdout).not_to eq('')
          expect(all_stdout).to include(t_finished)
        end

        it 'with stop' do
          attribute_eq 'stop', true

          expect(last_command).to have_exit_status(0)
          expect(all_stdout).not_to include(t_droplet_shutdown)
          expect(all_stdout).not_to include(t_wait_until_create)
          expect(all_stdout).not_to include(t_snapshot_created(snapshot_name))
        end

        it 'with no stop' do
          attribute_eq 'stop', false

          expect(last_command).to have_exit_status(0)
          expect(all_stdout).to include(t_droplet_shutdown)
          expect(all_stdout).to include(t_wait_until_create)
          expect(all_stdout).to include(t_snapshot_created(snapshot_name))
        end

        it 'with clean' do
          attribute_eq 'clean', true

          expect(last_command).to have_exit_status(0)
          expect(all_stdout).to include(t_snapshots_cleaning(droplet_id))
        end

        it 'with no clean' do
          attribute_eq 'clean', false

          expect(last_command).to have_exit_status(0)
          expect(all_stdout).not_to include(t_snapshots_cleaning(droplet_id))
        end

        it 'with mail' do
          hash_attribute_eq(mail: mail_options)

          expect(last_command).to have_exit_status(0)
          expect(all_stdout).to include(t_sending_email)
        end

        it 'with no mail' do
          hash_attribute_eq

          expect(last_command).to have_exit_status(0)
          expect(all_stdout).not_to include(t_sending_email)
        end

        it 'with smtp' do
          hash_attribute_eq(smtp: smtp_options)

          expect(last_command).to have_exit_status(0)
        end

        it 'with no smtp' do
          hash_attribute_eq

          expect(last_command).to have_exit_status(0)
        end

        it 'with log' do
          FileUtils.remove_file(log_path, true)
          hash_attribute_eq(log)

          expect(last_command).to have_exit_status(0)
          expect(File.exist?(log_path)).to be_truthy
        end

        it 'with no log' do
          FileUtils.remove_file(log_path, true)
          hash_attribute_eq

          expect(last_command).to have_exit_status(0)
          expect(File.exist?(log_path)).to be_falsey
        end
      end

      context 'API V2' do
        let(:default_options_cli) { default_options.reject { |key, _| %w( droplets threads ).include?(key.to_s) }.merge(protocol: 2) }
        let(:event_id) { '7499' }
        let(:snapshot_name) { "example.com_#{DateTime.now.strftime('%Y_%m_%d')}" }

        include_context 'api_v2_helpers'
        it_behaves_like '.snap methods'

        context 'when no credentials' do
          it 'with warning about digitalocean credentials' do
            with_environment(cli_env_nil) do
              run "do_snapshot snap #{options_line}"

              expect(last_command).to have_exit_status(1)
              expect(all_stdout)
                .to include(t_wrong_keys('digital_ocean_access_token'))
            end
          end
        end

        context 'when different credentials' do
          let(:api_access_token) { "Bearer #{cli_keys_other[:digital_ocean_access_token]}" }

          it 'with no warning' do
            hash_attribute_eq(cli_keys_other)

            expect(last_command).to have_exit_status(0)
          end
        end
      end

      context 'API V1' do
        include_context 'api_v1_helpers'
        it_behaves_like '.snap methods'

        context 'when no credentials' do
          it 'with warning about digitalocean credentials' do
            with_environment(cli_env_nil) do
              run "do_snapshot snap #{options_line}"

              expect(last_command).to have_exit_status(1)
              expect(all_stdout)
                .to include(t_wrong_keys(%w( digital_ocean_client_id digital_ocean_api_key ).join(', ')))
            end
          end
        end

        context 'when different credentials' do
          let(:keys_uri) { "api_key=#{cli_keys_other[:digital_ocean_api_key]}&client_id=#{cli_keys_other[:digital_ocean_client_id]}" }

          it 'with no warning' do
            hash_attribute_eq(cli_keys_other)

            expect(last_command).to have_exit_status(0)
          end
        end
      end
    end

    context '.help' do
      it 'shows a help message' do
        run 'do_snapshot help'
        expect(all_stdout)
          .to match('Commands:')
      end

      it 'shows a help message for specific commands' do
        run 'do_snapshot help snap'
        expect(all_stdout).to include('`do_snapshot` able to create and cleanup snapshots on your droplets.')
      end

      it 'sure no warning about credentials' do
        with_environment(cli_env_nil) do
          run 'do_snapshot help snap'

          expect(last_command).to have_exit_status(0)
          expect(all_stdout)
            .not_to include(t_wrong_keys(%w( digital_ocean_client_id digital_ocean_api_key ).join(', ')))
        end
      end
    end

    context '.version' do
      it 'with right version' do
        run 'do_snapshot version'
        expect(all_stdout).to include(DoSnapshot::VERSION)
      end
    end

    def t_snapshot_created(name = snapshot_name)
      "Snapshot name: #{name} created successfully."
    end

    def t_snapshots_cleaning(id = droplet_id)
      "Cleaning up snapshots for droplet id: #{id}"
    end

    def t_droplet_shutdown
      'Shutting down droplet.'
    end

    def t_wait_until_create
      'Wait until snapshot will be created.'
    end

    def t_finished
      'All operations has been finished.'
    end

    def t_is_reached
      'of snapshots is reached'
    end

    def t_sending_email
      'Sending e-mail notification'
    end

    def t_wrong_keys(keys)
      "You must have #{keys.upcase} in environment or set it via options."
    end

    def attribute_eq(name, value)
      stub_all_api
      options = default_options_cli.merge(Hash[cli_keys].symbolize_keys).merge(:"#{name}" => value)
      run "do_snapshot snap #{options_line(options)}"
    end

    def hash_attribute_eq(hash = {})
      stub_all_api
      options = default_options_cli.merge(Hash[cli_keys].symbolize_keys).merge(hash)
      run "do_snapshot snap #{options_line(options)}"
    end

    def hash_attribute_eq_no_stub(hash)
      options = default_options_cli.merge(Hash[cli_keys].symbolize_keys).merge(hash)
      run "do_snapshot snap #{options_line(options)}"
    end
  end

  def options_line(options = default_options_cli) # rubocop:disable Metrics/PerceivedComplexity,Metrics/MethodLength,Metrics/AbcSize,Metrics/CyclomaticComplexity
    options.map do |key, value|
      if value.is_a?(String)
        "--#{key}=#{value}"
      elsif value.is_a?(FalseClass)
        "--no-#{key}"
      elsif value.is_a?(Numeric)
        "--#{key}=#{value}"
      elsif value.is_a?(Array)
        if value.size > 0
          "--#{key}=#{value.join(' ')}"
        else
          nil
        end
      elsif value.is_a?(Hash)
        if value.size > 0
          items = value.map { |param, setting| "#{param}:#{setting}" }.join(' ')
          "--#{key}=#{items}"
        else
          nil
        end
      else
        "--#{key}"
      end
    end.compact.join(' ')
  end
end
