# frozen_string_literal: true

module Reforge
  module Errors
    class MissingEnvVarError < Reforge::Error
      def initialize(message)
        super(message)
      end
    end
  end
end
