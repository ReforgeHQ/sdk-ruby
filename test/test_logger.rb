# frozen_string_literal: true
require 'test_helper'

class TestCLogger < Minitest::Test
  def setup
    Prefab::LoggerClient.send(:public, :get_path)
    Prefab::LoggerClient.send(:public, :get_loc_path)
    Prefab::LoggerClient.send(:public, :level_of)
    @logger = Prefab::LoggerClient.new($stdout)
  end

  def test_get_path
    assert_equal "test_l.foo_warn",
                 @logger.get_path("/Users/jdwyah/Documents/workspace/RateLimitInc/prefab-cloud-ruby/lib/test_l.rb",
                                  "foo_warn")

    assert_equal "active_support.log_subscriber.info",
                 @logger.get_path("/Users/jdwyah/.rvm/gems/ruby-2.3.3@forcerank/gems/activesupport-4.1.16/lib/active_support/log_subscriber.rb",
                                  "info")
    assert_equal "active_support.log_subscriber.info",
                 @logger.get_path("/Users/jeffdwyer/.asdf/installs/ruby/3.1.2/lib/ruby/gems/3.1.0/gems/activesupport-7.0.2.4/lib/active_support/log_subscriber.rb:130:in `info'",
                                  "info")
    assert_equal "unknown.info",
                 @logger.get_path(nil,
                                  "info")
  end

  def test_loc_resolution
    backtrace_location = Struct.new(:absolute_path, :base_label, :string) do
      def to_s
        string
      end
    end # https://ruby-doc.org/core-3.0.0/Thread/Backtrace/Location.html

    # verify that even if the Thread::Backtrace::Location does not have an absolute_location, we do our best
    assert_equal "active_support.log_subscriber.info",
                 @logger.get_loc_path(backtrace_location.new(nil,
                                                             "info",
                                                             "/Users/jeffdwyer/.asdf/installs/ruby/3.1.2/lib/ruby/gems/3.1.0/gems/activesupport-7.0.2.4/lib/active_support/log_subscriber.rb:130:in `info'"))
    assert_equal "test_l.info",
                 @logger.get_loc_path(backtrace_location.new("/Users/jdwyah/Documents/workspace/RateLimitInc/prefab-cloud-ruby/lib/test_l.rb",
                                                             "info",
                                                             "/Users/jeffdwyer/.asdf/installs/ruby/3.1.2/lib/ruby/gems/3.1.0/gems/activesupport-7.0.2.4/lib/active_support/log_subscriber.rb:130:in `info'"))
  end

  def test_level_of
    with_env("PREFAB_LOG_CLIENT_BOOTSTRAP_LOG_LEVEL", "info") do
      # env var overrides the default level
      assert_equal Logger::INFO,
                   @logger.level_of("app.models.user"), "PREFAB_LOG_CLIENT_BOOTSTRAP_LOG_LEVEL is info"

      @logger.set_config_client(MockConfigClient.new({}))
      assert_equal Logger::WARN,
                   @logger.level_of("app.models.user"), "default is warn"

      @logger.set_config_client(MockConfigClient.new("log-level.app" => :INFO))
      assert_equal Logger::INFO,
                   @logger.level_of("app.models.user")

      @logger.set_config_client(MockConfigClient.new("log-level.app" => :DEBUG))
      assert_equal Logger::DEBUG,
                   @logger.level_of("app.models.user")

      @logger.set_config_client(MockConfigClient.new("log-level.app" => :DEBUG,
                                                     "log-level.app.models" => :ERROR))
      assert_equal Logger::ERROR,
                   @logger.level_of("app.models.user"), "test leveling"
    end
  end

  def test_log_internal
    mockLogOut = Minitest::Mock.new
    mockLogOut.expect :write, nil do |arg|
      /W, \[.*\]  WARN -- test.path: : test message/.match(arg)
    end

    mockLogOut.expect :!=, false, [String]
    mockLogOut.expect :nil?, false

    @logger = Prefab::LoggerClient.new(mockLogOut)
    @logger.instance_variable_set('@logdev', mockLogOut)
    @logger.log_internal("test message", "test.path", "", Logger::WARN)
  end

  def test_log_internal
    logger, mock_logdev = mock_logger_expecting /W, \[.*\]  WARN -- test.path: : test message/
    logger.log_internal("test message", "test.path", "", Logger::WARN)
    mock_logdev.verify
  end

  def test_log_internal_unknown
    logger, mock_logdev = mock_logger_expecting /A, \[.*\]   ANY -- test.path: : test message/
    logger.log_internal("test message", "test.path", "", Logger::UNKNOWN)
    mock_logdev.verify
  end

  def test_log_internal_silencing
    logger, mock_logdev = mock_logger_expecting /W, \[.*\]  WARN -- test.path: : should log/, calls: 2
    logger.silence do
      logger.log_internal("should not log", "test.path", "", Logger::WARN)
    end
    logger.log_internal("should log", "test.path", "", Logger::WARN)
    mock_logdev.verify
  end

  def mock_logger_expecting pattern, configs = {}, calls: 1
    mock_logdev = Minitest::Mock.new
    mock_logdev.expect :write, nil do |arg|
      pattern.match(arg)
    end

    mock_logdev.expect :!=, false, [String]
    calls.times.each do
      mock_logdev.expect(:nil?, false)
    end

    logger = Prefab::LoggerClient.new(mock_logdev)
    logger.instance_variable_set('@logdev', mock_logdev)
    logger.set_config_client(MockConfigClient.new(configs))
    [logger, mock_logdev]
  end
end
