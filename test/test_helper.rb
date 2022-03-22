require 'minitest/autorun'
require 'prefab-cloud-ruby'

class MockBaseClient
  STAGING_ENV_ID = 1
  PRODUCTION_ENV_ID = 2
  TEST_ENV_ID = 3
  attr_reader :namespace, :logger, :project_env_id, :config_client

  def initialize(project_env_id: TEST_ENV_ID, namespace: "")
    @project_env_id = project_env_id
    @namespace = namespace
    @logger = Logger.new($stdout)
    @config_client = MockConfigClient.new
  end

  def project_id
    1
  end

  def project_env_id
    @project_env_id
  end

  def log_internal level, message
  end

  def config_value key
    @config_values[key]
  end

end

class MockConfigClient
  def initialize(config_values = {})
    @config_values = config_values
  end
  def get(key)
    @config_values[key]
  end

  def get_config(key)
    Prefab::Config.new(value: @config_values[key], key: key)
  end

  def mock_this_config key, config_value
    @config_values[key] = config_value
  end
end

class MockConfigLoader
  def calc_config
  end
end
