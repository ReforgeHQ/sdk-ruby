require 'prefab-cloud-ruby'
require 'rack'
require 'base64'
require 'json'

handler = Rack::Handler::Thin

#
# This is a very lightweight server that allows the compliance harness to excercise the prefab client
#
class RackApp
  def call(env)
    props = CGI::parse(env["QUERY_STRING"])
    props = JSON.parse(Base64.decode64(props["props"][0]))

    key = props["key"]
    namespace = props["namespace"]
    environment = props["environment"]
    user_key = props["user_key"]
    is_feature_flag = !props["feature_flag"].nil?

    client = Prefab::Client.new(
      api_key: "1-#{environment}-local_development_api_key", #sets environment
      namespace: namespace,
    )

    puts "Key #{key}"
    puts "User #{user_key}"
    puts "Environment #{environment}"
    puts "Namespace #{namespace}"
    puts "Props! #{props}"
    puts "is_feature_flag! #{is_feature_flag}"

    if is_feature_flag
      puts "EVALFF #{key} #{user_key}"
      rtn = client.feature_flag_client.get(key, user_key, []).to_s
    else
      rtn = client.config_client.get(key).to_s
    end
    puts "return #{rtn}"

    [200, { "Content-Type" => "text/plain" }, rtn]
  end
end

handler.run RackApp.new
