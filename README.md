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

