require "bundler/gem_tasks"
require "rake/testtask"

task default: :test

Rake::TestTask.new do |t|
  t.libs << "test"
  t.test_files = FileList["test/**/*_test.rb"]
  t.verbose = true
end

require_relative "lib/aufgaben/release"
require_relative "lib/aufgaben/version"
Aufgaben::Release.new(:release_new) do |t|
  t.new_version = Aufgaben::VERSION
end

require_relative "lib/aufgaben/bump/ruby"
Aufgaben::Bump::Ruby.new
