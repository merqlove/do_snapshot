# -*- encoding : utf-8 -*-
require 'logger'

module DoSnapshot
  # Shared logger
  #
  class Log
    attr_reader :shell
    attr_accessor :quiet, :verbose
    attr_writer :buffer, :instance

    def initialize(options={})
      @verbose = DoSnapshot.config.verbose
      @quiet   = DoSnapshot.config.quiet
      options.each { |key, option| instance_variable_set(:"@#{key}", option) }
      instance.level = DoSnapshot.config.logger_level if instance
    end

    def instance
      @instance ||= DoSnapshot.config.logger
    end

    def buffer
      @buffer ||= %w()
    end

    def shell=(shell)
      @shell = shell unless quiet
    end

    def close
      instance.close if instance
    end

    %w(debug info warn error fatal unknown).each_with_index do |name, severity|
      define_method(:"#{name}") { |*args, &block| log severity, *args, &block }
    end

    def log(severity, message = nil, progname = nil , &block)
      buffer << message
      instance.add(severity, message, progname, &block) if instance

      say message, color(severity) unless print?(severity)
    end

    protected

    def print?(type)
      (type == :debug && !verbose) || quiet
    end

    def say(message, color)
      shell.say message, color if shell
    end

    def color(severity)
      case severity
      when 0
        :white
      when 3
        :red
      when 2
        :yellow
      else
        :green
      end
    end
  end
end
