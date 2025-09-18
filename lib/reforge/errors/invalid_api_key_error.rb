# frozen_string_literal: true

module Reforge
  module Errors
    class InvalidApiKeyError < Reforge::Error
      def initialize(key)
        if key.nil? || key.empty?
          message = 'No API key. Set PREFAB_API_KEY env var or use PREFAB_DATASOURCES=LOCAL_ONLY'

          super(message)
        else
          message = "Your API key format is invalid. Expecting something like 123-development-yourapikey-SDK. You provided `#{key}`"

          super(message)
        end
      end
    end
  end
end
