# frozen_string_literal: true

module Reforge
  class LogLevelClient
    LOG = Reforge::InternalLogger.new(self)

    # Map from our LogLevel symbols to SemanticLogger numeric severity levels
    # SemanticLogger levels: trace=0, debug=1, info=2, warn=3, error=4, fatal=5
    SEMANTIC_LOGGER_LEVELS = {
      trace: 0,
      debug: 1,
      info: 2,
      warn: 3,
      error: 4,
      fatal: 5
    }.freeze

    def initialize(base_client)
      @base_client = base_client
    end

    # Check if a log message should be logged based on severity and logger path
    # @param severity [Integer] SemanticLogger severity level (0-5)
    # @param path [String] Logger path/name
    # @return [Boolean] true if the message should be logged
    def should_log?(severity, path)
      configured_level = get_log_level(path)
      configured_severity = SEMANTIC_LOGGER_LEVELS[configured_level]
      severity >= configured_severity
    end

    # SemanticLogger filter integration
    # @param log [SemanticLogger::Log] The log entry to filter
    # @return [Boolean] true if the log should be output
    def semantic_filter(log)
      class_path = class_path_name(log.name)
      level = SemanticLogger::Levels.index(log.level)
      log.named_tags.merge!({ path: class_path })
      should_log?(level, class_path)
    end

    # Get the log level for a given logger name
    # Returns a LogLevel symbol (:trace, :debug, :info, :warn, :error, :fatal)
    # Defaults to :debug if no config is found
    def get_log_level(logger_name)
      logger_key = @base_client.options.logger_key

      # If logger key is explicitly set to nil or empty, return default
      if logger_key.nil? || logger_key.empty?
        LOG.debug "logger_key is nil or empty, returning default log level DEBUG"
        return Reforge::LogLevel::DEBUG
      end

      # Create the evaluation context
      context = {
        "reforge-sdk-logging" => {
          "lang" => "ruby",
          "logger-path" => logger_name
        }
      }

      # Get the raw config to check its type first
      raw_config = @base_client.config_client.resolver.raw(logger_key)

      if raw_config.nil?
        LOG.debug "No raw config found for key '#{logger_key}', returning default DEBUG"
        return Reforge::LogLevel::DEBUG
      end

      # Verify it's a LOG_LEVEL_V2 config
      if raw_config.config_type != :LOG_LEVEL_V2
        LOG.warn "Config '#{logger_key}' is not a LOG_LEVEL_V2 config (type: #{raw_config.config_type}), returning default DEBUG"
        return Reforge::LogLevel::DEBUG
      end

      begin
        # Evaluate the config with the context
        evaluation = @base_client.config_client.send(:_get, logger_key, context)

        if evaluation.nil?
          LOG.debug "No log level config found for key '#{logger_key}', returning default DEBUG"
          return Reforge::LogLevel::DEBUG
        end

        # Get the unwrapped value - this returns a PrefabProto::LogLevel enum value
        proto_log_level = evaluation.report_and_return(@base_client.evaluation_summary_aggregator)

        # Convert the proto LogLevel to our public LogLevel enum
        Reforge::LogLevel.from_proto(proto_log_level)
      rescue => e
        LOG.warn "Error getting log level for '#{logger_name}': #{e.message}"
        LOG.debug e.backtrace.join("\n")
        Reforge::LogLevel::DEBUG
      end
    end

    private

    # Convert a logger class name to a path format
    # e.g., "MyApp::MyClass" becomes "my_app.my_class"
    def class_path_name(class_name)
      begin
        log_class = Object.const_get(class_name)
        if log_class.respond_to?(:superclass) && log_class.superclass != Object
          underscore("#{log_class.superclass.name}.#{log_class.name}")
        else
          underscore(log_class.name.to_s)
        end.gsub(/[^a-z_]/i, '.')
      rescue NameError
        # If we can't resolve the constant, just underscore the name
        underscore(class_name.to_s).gsub(/[^a-z_]/i, '.')
      end
    end

    # Convert CamelCase to snake_case
    def underscore(string)
      string.gsub(/::/, '/').
        gsub(/([A-Z]+)([A-Z][a-z])/, '\1_\2').
        gsub(/([a-z\d])([A-Z])/, '\1_\2').
        tr("-", "_").
        downcase
    end
  end
end
