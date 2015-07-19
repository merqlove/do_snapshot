require 'do_snapshot/cli'

module DoSnapshot
  class Runner
    def initialize(argv, stdin = STDIN, stdout = STDOUT, stderr = STDERR, kernel = Kernel)
      @argv, @stdin, @stdout, @stderr, @kernel = argv, stdin, stdout, stderr, kernel
    end

    def execute!
      exit_code = begin
        $stderr = @stderr
        $stdin = @stdin
        $stdout = @stdout

        DoSnapshot::CLI.start(@argv)

        0
      rescue DoSnapshot::NoTokenError, DoSnapshot::NoKeysError => _
        clean
        1
      rescue StandardError => e
        b = e.backtrace
        @stderr.puts("#{b.shift}: #{e.message} (#{e.class})")
        @stderr.puts(b.map{|s| "\tfrom #{s}"}.join("\n"))
        1
      rescue SystemExit => e
        e.status
      ensure
        clean
      end

      @kernel.exit(exit_code)
    end

    # For tests
    #
    def parent_instance
      DoSnapshot
    end

    private

    def clean
      DoSnapshot.cleanup

      $stderr = STDERR
      $stdin = STDIN
      $stdout = STDOUT
    end
  end
end
