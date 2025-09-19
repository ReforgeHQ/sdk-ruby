# frozen_string_literal: true

require 'test_helper'

class TestConfigClient < Minitest::Test
  def setup
    super
    options = Reforge::Options.new(
      prefab_datasources: Reforge::Options::DATASOURCES::LOCAL_ONLY,
      x_use_local_cache: true,
    )

    @config_client = Reforge::ConfigClient.new(MockBaseClient.new(options), 10)
  end


  def test_initialization_timeout_error
    options = Reforge::Options.new(
      sdk_key: '123-ENV-KEY-SDK',
      initialization_timeout_sec: 0.01
    )

    err = assert_raises(Reforge::Errors::InitializationTimeoutError) do
      Reforge::Client.new(options).config_client.get('anything')
    end

    assert_match(/couldn't initialize in 0.01 second timeout/, err.message)
  end


  def test_invalid_api_key_error
    options = Reforge::Options.new(
      sdk_key: ''
    )

    err = assert_raises(Reforge::Errors::InvalidSdkKeyError) do
      Reforge::Client.new(options).config_client.get('anything')
    end

    assert_match(/No SDK key/, err.message)

    options = Reforge::Options.new(
      sdk_key: 'invalid'
    )

    err = assert_raises(Reforge::Errors::InvalidSdkKeyError) do
      Reforge::Client.new(options).config_client.get('anything')
    end

    assert_match(/format is invalid/, err.message)
  end

  def test_caching
    @config_client.send(:cache_configs,
                        PrefabProto::Configs.new(configs:
                                                   [PrefabProto::Config.new(key: 'test', id: 1,
                                                                            rows: [PrefabProto::ConfigRow.new(
                                                                              values: [
                                                                                PrefabProto::ConditionalValue.new(
                                                                                  value: PrefabProto::ConfigValue.new(string: "test value")
                                                                                )
                                                                              ]
                                                                            )])],
                                                 config_service_pointer: PrefabProto::ConfigServicePointer.new(project_id: 3, project_env_id: 5)))
    @config_client.send(:load_cache)
    assert_equal "test value", @config_client.get("test")
  end

  def test_cache_path_respects_xdg
    options = Reforge::Options.new(
      prefab_datasources: Reforge::Options::DATASOURCES::LOCAL_ONLY,
      x_use_local_cache: true,
      sdk_key: "123-ENV-KEY-SDK",)

    config_client = Reforge::ConfigClient.new(MockBaseClient.new(options), 10)
    assert_equal "#{Dir.home}/.cache/prefab.cache.123.json", config_client.send(:cache_path)

    with_env('XDG_CACHE_HOME', '/tmp') do
      config_client = Reforge::ConfigClient.new(MockBaseClient.new(options), 10)
      assert_equal "/tmp/prefab.cache.123.json", config_client.send(:cache_path)
    end
  end

end
