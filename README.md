# Reforge SDK for Ruby

Ruby Client for Reforge Feature Flags and Config as a Service: https://launch.reforge.com

```ruby
Reforge.init

context = {
  user: {
    team_id: 432,
    id: 123,
    subscription_level: 'pro',
    email: "alice@example.com"
  }
}

result = Reforge.enabled? "my-first-feature-flag", context

puts "my-first-feature-flag is: #{result}"
```

See full documentation https://docs.reforge.com/docs/sdks/ruby

## Supports

- Feature Flags
- Live Config
- WebUI for tweaking config and feature flags

## Installation

Add the gem to your Gemfile:

```ruby
gem 'sdk-reforge'
```

Or install directly:

```bash
gem install sdk-reforge
```

## Important note about Forking and realtime updates

Many ruby web servers fork. When the process is forked, the current realtime update stream is disconnected. If you're using Puma or Unicorn, do the following.

```ruby
#config/application.rb
Reforge.init # reads REFORGE_BACKEND_SDK_KEY env var by default
```

```ruby
#puma.rb
on_worker_boot do
  Reforge.fork
end
```

```ruby
# unicorn.rb
after_fork do |server, worker|
  Reforge.fork
end
```

## Dynamic Log Levels

Reforge supports dynamic log level management for Ruby logging frameworks. This allows you to change log levels in real-time without redeploying your application.

Supported loggers:
- SemanticLogger (optional dependency)
- Ruby stdlib Logger

### Setup with SemanticLogger

Add semantic_logger to your Gemfile:

```ruby
# Gemfile
gem "semantic_logger"
```

### Plain Ruby

```ruby
require "semantic_logger"
require "sdk-reforge"

client = Reforge::Client.new(
  sdk_key: ENV['REFORGE_BACKEND_SDK_KEY'],
  logger_key: 'log-levels.default' # optional, this is the default
)

SemanticLogger.sync!
SemanticLogger.default_level = :trace # Reforge will handle filtering
SemanticLogger.add_appender(
  io: $stdout,
  formatter: :json,
  filter: client.log_level_client.method(:semantic_filter)
)
```

### With Rails

```ruby
# Gemfile
gem "amazing_print"
gem "rails_semantic_logger"
```

```ruby
# config/application.rb
$reforge_client = Reforge::Client.new # reads REFORGE_BACKEND_SDK_KEY env var

# config/initializers/logging.rb
SemanticLogger.sync!
SemanticLogger.default_level = :trace # Reforge will handle filtering
SemanticLogger.add_appender(
  io: $stdout,
  formatter: Rails.env.development? ? :color : :json,
  filter: $reforge_client.log_level_client.method(:semantic_filter)
)
```

```ruby
# puma.rb
on_worker_boot do
  SemanticLogger.reopen
  Reforge.fork
end
```

### With Ruby stdlib Logger

If you're using Ruby's standard library Logger, you can use a dynamic formatter:

```ruby
require "logger"
require "sdk-reforge"

client = Reforge::Client.new(
  sdk_key: ENV['REFORGE_BACKEND_SDK_KEY'],
  logger_key: 'log-levels.default' # optional, this is the default
)

logger = Logger.new($stdout)
logger.level = Logger::DEBUG # Set to most verbose level, Reforge will handle filtering
logger.formatter = client.log_level_client.stdlib_formatter('MyApp')
```

The formatter will check dynamic log levels from Reforge and only output logs that meet the configured threshold.

### Configuration

In Reforge Launch, create a `LOG_LEVEL_V2` config with your desired key (default: `log-levels.default`). The config will be evaluated with the following context:

```ruby
{
  "reforge-sdk-logging" => {
    "lang" => "ruby",
    "logger-path" => "your_app.your_class" # class name converted to lowercase with dots
  }
}
```

You can set different log levels for different classes/modules using criteria on the `reforge-sdk-logging.logger-path` property.

## Contributing to reforge sdk for ruby

- Check out the latest master to make sure the feature hasn't been implemented or the bug hasn't been fixed yet.
- Check out the issue tracker to make sure someone already hasn't requested it and/or contributed it.
- Fork the project.
- Start a feature/bugfix branch.
- Commit and push until you are happy with your contribution.
- Make sure to add tests for it. This is important so I don't break it in a future version unintentionally.
- Please try not to mess with the Rakefile, version, or history. If you want to have your own version, or is otherwise necessary, that is fine, but please isolate to its own commit so I can cherry-pick around it.

## Release

Release is automated via GitHub Actions using RubyGems trusted publishing. When tests pass on the main branch, a new version is automatically published to RubyGems.

To release a new version:

```shell
# Update the version
echo "1.9.1" > VERSION

# Update the changelog with your changes
# Edit CHANGELOG.md

# Regenerate the gemspec
bundle exec rake gemspec:generate

# Create PR with changes
git checkout -b release-1.9.1
git commit -am "Release 1.9.1"
git push origin release-1.9.1
# Then create and merge PR to main
```

## Copyright

Copyright (c) 2025 Reforge Inc. See LICENSE.txt for further details.

