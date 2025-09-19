# frozen_string_literal: true

require 'test_helper'

class TestPrefab < Minitest::Test



  private

  def init_once
    unless Reforge.instance_variable_get("@singleton")
      Reforge.init(prefab_options)
    end
  end
end
