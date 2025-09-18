# frozen_string_literal: true

require 'uuid'

module Reforge
  class Client
    LOG = Reforge::InternalLogger.new(self)
    MAX_SLEEP_SEC = 10
    BASE_SLEEP_SEC = 0.5

    attr_reader :namespace, :interceptor, :sdk_key, :options, :instance_hash

    def initialize(options = Reforge::Options.new)
      @options = options.is_a?(Reforge::Options) ? options : Reforge::Options.new(options)
      @namespace = @options.namespace
      @stubs = {}
      @instance_hash = ::UUID.new.generate

      if @options.local_only?
        LOG.debug 'Prefab Running in Local Mode'
      elsif @options.datafile?
        LOG.debug 'Prefab Running in DataFile Mode'
      else
        @sdk_key = @options.sdk_key
        raise Reforge::Errors::InvalidSdkKeyError, @sdk_key if @sdk_key.nil? || @sdk_key.empty? || sdk_key.count('-') < 1
      end

      context.clear

      Reforge::Context.global_context = @options.global_context

      # start config client
      config_client
    end

    def with_context(properties, &block)
      Reforge::Context.with_context(properties, &block)
    end

    def context
      Reforge::Context.current
    end

    def config_client(timeout: 5.0)
      @config_client ||= Reforge::ConfigClient.new(self, timeout)
    end

    def stop
      @config_client.stop
    end

    def feature_flag_client
      @feature_flag_client ||= Reforge::FeatureFlagClient.new(self)
    end

    def log_path_aggregator
      return nil if @options.collect_max_paths <= 0

      @log_path_aggregator ||= LogPathAggregator.new(client: self, max_paths: @options.collect_max_paths,
                                                     sync_interval: @options.collect_sync_interval)
    end

    def log
      @log ||= Reforge::LoggerClient.new(client: self, log_path_aggregator: log_path_aggregator)
    end

    def context_shape_aggregator
      return nil if @options.collect_max_shapes <= 0

      @context_shape_aggregator ||= ContextShapeAggregator.new(client: self, max_shapes: @options.collect_max_shapes,
                                                               sync_interval: @options.collect_sync_interval)
    end

    def example_contexts_aggregator
      return nil if @options.collect_max_example_contexts <= 0

      @example_contexts_aggregator ||= ExampleContextsAggregator.new(
        client: self,
        max_contexts: @options.collect_max_example_contexts,
        sync_interval: @options.collect_sync_interval
      )
    end

    def evaluation_summary_aggregator
      return nil if @options.collect_max_evaluation_summaries <= 0

      @evaluation_summary_aggregator ||= EvaluationSummaryAggregator.new(
        client: self,
        max_keys: @options.collect_max_evaluation_summaries,
        sync_interval: @options.collect_sync_interval
      )
    end

    def set_rails_loggers
      warn '[DEPRECATION] `set_rails_loggers` is deprecated since 1.6. Please use semantic_logger or `Prefab.log_filter` instead.'
    end

    def on_update(&block)
      resolver.on_update(&block)
    end

    def enabled?(feature_name, jit_context = NO_DEFAULT_PROVIDED)
      feature_flag_client.feature_is_on_for?(feature_name, jit_context)
    end

    def get(key, default = NO_DEFAULT_PROVIDED, jit_context = NO_DEFAULT_PROVIDED)
      if is_ff?(key)
        feature_flag_client.get(key, jit_context, default: default)
      else
        config_client.get(key, default, jit_context)
      end
    end

    def post(path, body)
      Reforge::HttpConnection.new(@options.telemetry_destination, @sdk_key).post(path, body)
    end

    def inspect
      "#<Reforge::Client:#{object_id} namespace=#{namespace}>"
    end

    def resolver
      config_client.resolver
    end

    # When starting a forked process, use this to re-use the options
    # on_worker_boot do
    #   Prefab.fork
    # end
    def fork
      Reforge::Client.new(@options.for_fork)
    end

    def defined?(key)
      !!config_client.send(:raw, key)
    end

    def is_ff?(key)
      raw = config_client.send(:raw, key)

      raw && raw.allowable_values.any?
    end
  end
end
