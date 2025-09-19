# frozen_string_literal: true

require 'test_helper'

class TestFeatureFlagClient < Minitest::Test
  DEFAULT = 'default'




  private

  def new_client(overrides = {})
    super(overrides).feature_flag_client
  end
end
