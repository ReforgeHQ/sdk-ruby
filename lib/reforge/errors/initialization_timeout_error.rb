# frozen_string_literal: true

module Reforge
  module Errors
    class InitializationTimeoutError < Reforge::Error
      def initialize(timeout_sec, key)
        message = "Reforge SDK couldn't initialize in #{timeout_sec} second timeout. Trying to fetch key `#{key}`."
        super(message)
      end
    end
  end
end
