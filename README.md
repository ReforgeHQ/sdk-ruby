# prefab-cloud-ruby

Ruby Client for Reforge Feature Flags, Dynamic log levels, and Config as a Service: https://launch.reforge.com

```ruby
client = Reforge::Client.new

context = {
  user: {
    team_id: 432,
    id: 123,
    subscription_level: 'pro',
    email: "alice@example.com"
  }
}

result = client.enabled? "my-first-feature-flag", context

puts "my-first-feature-flag is: #{result}"
```

See full documentation https://docs.prefab.cloud/docs/sdks/ruby

## Supports

- Feature Flags
- Live Config
- WebUI for tweaking config, log levels, and feature flags

## Important note about Forking and realtime updates

Many ruby web servers fork. When the process is forked, the current realtime update stream is disconnected. If you're using Puma or Unicorn, do the following.

```ruby
#config/application.rb
Prefab.init # reads REFORGE_SDK_KEY env var by default
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



## Contributing to prefab-cloud-ruby

- Check out the latest master to make sure the feature hasn't been implemented or the bug hasn't been fixed yet.
- Check out the issue tracker to make sure someone already hasn't requested it and/or contributed it.
- Fork the project.
- Start a feature/bugfix branch.
- Commit and push until you are happy with your contribution.
- Make sure to add tests for it. This is important so I don't break it in a future version unintentionally.
- Please try not to mess with the Rakefile, version, or history. If you want to have your own version, or is otherwise necessary, that is fine, but please isolate to its own commit so I can cherry-pick around it.

## Release

```shell
update the changelog
update VERSION
bundle exec rake gemspec:generate
git commit & push
REMOTE_BRANCH=main LOCAL_BRANCH=main bundle exec rake release
```

## Copyright

Copyright (c) 2024 Prefab, Inc. See LICENSE.txt for further details.

[semantic logger]: https://logger.rocketjob.io/
