module DoSnapshot
  # Configuration class. Used to share config across application.
  #
  class Configuration
    attr_accessor :logger
    attr_accessor :logger_level
    attr_accessor :verbose
    attr_accessor :quiet
    attr_accessor :mailer

    def initialize
      @logger  = nil
      @logger_level = Logger::INFO
      @verbose = false
      @quiet   = false
      @mailer  = nil
    end
  end
end
