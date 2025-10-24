# frozen_string_literal: true

module Reforge
  # Internal logger for the Reforge SDK
  # Uses SemanticLogger if available, falls back to stdlib Logger
  class InternalLogger
    def initialize(klass)
      @klass = klass

      if defined?(SemanticLogger)
        @logger = create_semantic_logger
        @using_semantic = true
      else
        @logger = create_stdlib_logger
        @using_semantic = false
      end

      instances << self if @using_semantic
    end

    # Log methods
    def trace(message = nil, &block)
      log_message(:trace, message, &block)
    end

    def debug(message = nil, &block)
      log_message(:debug, message, &block)
    end

    def info(message = nil, &block)
      log_message(:info, message, &block)
    end

    def warn(message = nil, &block)
      log_message(:warn, message, &block)
    end

    def error(message = nil, &block)
      log_message(:error, message, &block)
    end

    def fatal(message = nil, &block)
      log_message(:fatal, message, &block)
    end

    def level
      if @using_semantic
        @logger.level
      else
        # Map Logger constant back to symbol
        case @logger.level
        when Logger::DEBUG then :debug
        when Logger::INFO then :info
        when Logger::WARN then :warn
        when Logger::ERROR then :error
        when Logger::FATAL then :fatal
        else :warn
        end
      end
    end

    def level=(new_level)
      if @using_semantic
        @logger.level = new_level
      else
        # Map symbol to Logger constant
        @logger.level = case new_level
                       when :trace, :debug then Logger::DEBUG
                       when :info then Logger::INFO
                       when :warn then Logger::WARN
                       when :error then Logger::ERROR
                       when :fatal then Logger::FATAL
                       else Logger::WARN
                       end
      end
    end

    # Our client outputs debug logging,
    # but if you aren't using Reforge logging this could be too chatty.
    # If you aren't using reforge log filter, only log warn level and above
    def self.using_reforge_log_filter!
      return unless defined?(SemanticLogger)
      @@instances&.each do |logger|
        logger.level = :trace
      end
    end

    private

    def create_semantic_logger
      default_level = env_log_level || :warn
      logger = SemanticLogger::Logger.new(@klass, default_level)

      # Wrap to prevent recursion
      class << logger
        def log(log, message = nil, progname = nil, &block)
          return if recurse_check[local_log_id]
          recurse_check[local_log_id] = true
          begin
            super(log, message, progname, &block)
          ensure
            recurse_check[local_log_id] = false
          end
        end

        def local_log_id
          Thread.current.__id__
        end

        private

        def recurse_check
          @recurse_check ||= Concurrent::Map.new(initial_capacity: 2)
        end
      end

      logger
    end

    def create_stdlib_logger
      require 'logger'
      # Create a wrapper that dynamically checks for $logs (used in tests)
      output_wrapper = Object.new
      def output_wrapper.write(msg)
        # Check for $logs at write time (not initialization time)
        output = defined?($logs) && $logs ? $logs : $stderr
        output.write(msg)
      end

      def output_wrapper.close
        # No-op to satisfy Logger interface
      end

      logger = Logger.new(output_wrapper)
      logger.level = case env_log_level
                    when :trace, :debug then Logger::DEBUG
                    when :info then Logger::INFO
                    when :warn then Logger::WARN
                    when :error then Logger::ERROR
                    when :fatal then Logger::FATAL
                    else Logger::WARN
                    end
      logger.progname = @klass.to_s
      logger
    end

    def env_log_level
      level_str = ENV['REFORGE_LOG_CLIENT_BOOTSTRAP_LOG_LEVEL']
      level_str&.downcase&.to_sym
    end

    def log_message(level, message, &block)
      if @using_semantic
        @logger.send(level, message, &block)
      else
        # stdlib Logger doesn't have trace
        level = :debug if level == :trace
        @logger.send(level, message || block&.call)
      end
    end

    def instances
      @@instances ||= []
    end
  end
end
