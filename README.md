[![Gem Version](https://badge.fury.io/rb/aufgaben.svg)](https://badge.fury.io/rb/aufgaben)

# Aufgaben

The collection of useful Rake tasks.

## Installation

Add this line to your `Gemfile`:

```ruby
gem "aufgaben", require: false
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
  t.default_branch = "main"
  t.dry_run = false
  t.changelog = "CHANGELOG.md"
  t.files = []
  t.new_version = nil # from the CLI argument
end
```

The following is a customization example:

```ruby
Aufgaben::Release.new(:my_release_task_name, depends: [:test]) do |t|
  t.default_branch = "development"
  t.changelog = "changes.md"
  t.files = FileList["lib/version.rb", "lib/**/ver.rb"]
end
```

And then execute:

```console
$ rake release'[1.2.3]'
```

Or in dry-run mode:

```console
$ rake release'[1.2.3]' DRY_RUN=1
```

By default, the release task is executed in interactive mode.
If you want to disable the interactive mode, run as follow:

```console
$ rake release'[1.2.3]' NONINTERACTIVE=1
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

```console
$ rake bump:ruby'[2.6.5]' [DRY_RUN=1]
```

Also, you can customize the task name or dependencies as follows:

```ruby
require "aufgaben/bump/ruby"
Aufgaben::Bump::Ruby.new(:ruby_files, :update, dependes: [:test])
```

```console
# Invoke the `test` task before
$ rake update:ruby_files'[2.7.2]'
```

### Bumping up Node.js

Configure your `Rakefile` as follows:

```ruby
require "aufgaben/bump/nodejs"
Aufgaben::Bump::Nodejs.new do |t|
  t.files << "Dockerfile.production" # defaults to ["Dockerfile"]
  t.version_files << "nodejs-version.txt" # defaults to [".node-version", ".nvmrc"]
end
```

And then execute:

```console
$ rake bump:nodejs'[12.16.1]' [DRY_RUN=1]
```

## Development

To set up:

```console
bin/setup
```

To run an interactive prompt:

```console
bin/console
```

To release:

Run manually on the [Release workflow](https://github.com/ybiquitous/aufgaben/actions/workflows/release.yml).

## Contributing

Bug reports and pull requests are welcome on GitHub at <https://github.com/ybiquitous/aufgaben>.
