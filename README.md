# Aufgaben

> Provide useful Rake tasks

## Installation

Add this line to your `Gemfile`:

```ruby
gem "aufgaben"
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install aufgaben

## Usage

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
end
```

And then execute:

    $ rake release'[1.2.3]'

Or in dry-run mode:

    $ rake release'[1.2.3]' DRY_RUN=1

## Development

After checking out the repo, run `bin/setup` to install dependencies. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at <https://github.com/ybiquitous/aufgaben>.
