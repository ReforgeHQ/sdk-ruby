# frozen_string_literal: true

module Reforge
  module Errors
    class InvalidSdkKeyError < Reforge::Error
      def initialize(key)
        if key.nil? || key.empty?
          message = 'No SDK key. Set REFORGE_SDK_KEY env var or use PREFAB_DATASOURCES=LOCAL_ONLY'

          super(message)
        else
          message = "Your SDK key format is invalid. Expecting something like 123-development-yourapikey-SDK. You provided `#{key}`"

          super(message)
        end
      end
    end
  end
end
