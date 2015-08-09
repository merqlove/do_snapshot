require 'do_snapshot/cli'

module DoSnapshot
  # CLI Runner
  #
  class Runner
    def initialize(argv, stdin = STDIN, stdout = STDOUT, stderr = STDERR, kernel = Kernel)
      @argv = argv
      @stdin = stdin
      @stdout = stdout
      @stderr = stderr
      @kernel = kernel
    end

    def execute! # rubocop:disable Metrics/MethodLength
      exit_code = begin
        run_cli
      rescue DoSnapshot::NoTokenError, DoSnapshot::NoKeysError => _
        do_nothing_on_shown_error
      rescue StandardError => e
        display_backtrace_otherwise(e)
      rescue SystemExit => e
        e.status
      ensure
        clean_before_exit
      end

      @kernel.exit(exit_code)
    end

    private

    def run_cli
      $stderr = @stderr
      $stdin = @stdin
      $stdout = @stdout

      DoSnapshot::CLI.start(@argv)

      0
    end

    def do_nothing_on_shown_error
      clean_before_exit
      1
    end

    def display_backtrace_otherwise(e)
      b = e.backtrace
      @stderr.puts("#{b.shift}: #{e.message} (#{e.class})")
      @stderr.puts(b.map { |s| "\tfrom #{s}" }.join("\n"))
      1
    end

    def clean_before_exit
      DoSnapshot.cleanup

      $stderr = STDERR
      $stdin = STDIN
      $stdout = STDOUT
    end
  end
end
