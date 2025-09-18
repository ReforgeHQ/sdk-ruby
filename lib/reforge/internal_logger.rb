module Reforge
  class InternalLogger < SemanticLogger::Logger

    def initialize(klass)
      default_level = ENV['REFORGE_LOG_CLIENT_BOOTSTRAP_LOG_LEVEL'] ? ENV['REFORGE_LOG_CLIENT_BOOTSTRAP_LOG_LEVEL'].downcase.to_sym : :warn
      super(klass, default_level)
      instances << self
    end

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

    # Our client outputs debug logging,
    # but if you aren't using Reforge logging this could be too chatty.
    # If you aren't using reforge log filter, only log warn level and above
    def self.using_reforge_log_filter!
      @@instances.each do |l|
        l.level = :trace
      end
    end

    private

    def instances
      @@instances ||= []
    end

    def recurse_check
      @recurse_check ||=Concurrent::Map.new(initial_capacity: 2)
    end
  end
end
