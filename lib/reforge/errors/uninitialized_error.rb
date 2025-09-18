# frozen_string_literal: true

module Reforge
  module Errors
    class UninitializedError < Reforge::Error
      def initialize(key=nil)
        message = "Use Reforge.initialize before calling Reforge.get #{key}"

        super(message)
      end
    end
  end
end
