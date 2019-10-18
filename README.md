# Aufgaben

> Provide useful Rake tasks

## Installation

Add this line to your `Gemfile`:

```ruby
gem "aufgaben"
```

And then execute:

```shell
$ bundle
```

Or install it yourself as:

```shell
$ gem install aufgaben
```

## Usage

### Releasing

Put the following code to your `Rakefile`:

```ruby
require "aufgaben/release"
Aufgaben::Release.new
```

The default settings:

```ruby
Aufgaben::Release.new do |t|
  t.default_branch = "master"
  t.dry_run = false
  t.changelog = "CHANGELOG.md"
  t.files = []
  t.new_version = nil # from the CLI argument
end
```

The following is a customization example:

```ruby
Aufgaben::Release.new(:my_release_task_name) do |t|
  t.default_branch = "development"
  t.changelog = "changes.md"
  t.files = ["lib/version.rb", "lib/**/ver.rb"] # glob available
end
```

And then execute:

```shell
$ rake release'[1.2.3]'
```

Or in dry-run mode:

```shell
$ rake release'[1.2.3]' DRY_RUN=1
```

### Bumping up Ruby

Configure your `Rakefile` as follows:

```ruby
require "aufgaben/bump/ruby"
Aufgaben::Bump::Ruby.new do |t|
  t.files << "my-ruby-version-file" # defaults to [".ruby-version", "Dockerfile"]
end
```

And then execute:

```shell
$ rake bump:ruby'[2.6.5]' [DRY_RUN=1]
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at <https://github.com/ybiquitous/aufgaben>.
