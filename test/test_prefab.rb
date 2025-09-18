# frozen_string_literal: true

require 'test_helper'

class TestPrefab < Minitest::Test
  def test_get
    init_once

    assert_equal 'default', Reforge.get('does.not.exist', 'default')
    assert_equal 'default', Reforge.get('does.not.exist', 'default', { some: { key: 'value' } })
    assert_equal 'test sample value', Reforge.get('sample')
    assert_equal 123, Reforge.get('sample_int')

    ctx = { user: { key: 'jimmy' } }
    assert_equal 'default-goes-here', Reforge.get('user_key_match', 'default-goes-here', ctx)

    ctx = { user: { key: 'abc123' } }
    assert_equal true, Reforge.get('user_key_match', nil, ctx)
  end

  def test_defined
    init_once

    refute Reforge.defined?('does_not_exist')
    assert Reforge.defined?('sample_int')
    assert Reforge.defined?('disabled_flag')
  end

  def test_is_ff
    init_once

    assert Reforge.is_ff?('flag_with_a_value')
    refute Reforge.is_ff?('sample_int')
    refute Reforge.is_ff?('does_not_exist')
  end

  private

  def init_once
    unless Reforge.instance_variable_get("@singleton")
      Reforge.init(prefab_options)
    end
  end
end
