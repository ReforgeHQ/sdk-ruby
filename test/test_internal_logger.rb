# frozen_string_literal: true

require 'test_helper'

class TestInternalLogger < Minitest::Test

  def test_levels
    logger_a = Reforge::InternalLogger.new(A)
    logger_b = Reforge::InternalLogger.new(B)

    assert_equal :warn, logger_a.level
    assert_equal :warn, logger_b.level

    Reforge::InternalLogger.using_reforge_log_filter!

    # With SemanticLogger, level goes to :trace (semantic filter controls output)
    # Without SemanticLogger, level stays at :warn (prevents log flooding)
    if defined?(SemanticLogger)
      assert_equal :trace, logger_a.level
      assert_equal :trace, logger_b.level
    else
      assert_equal :warn, logger_a.level
      assert_equal :warn, logger_b.level
    end
  end

end

class A
end

class B
end
