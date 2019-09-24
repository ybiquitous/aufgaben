require "bundler/gem_tasks"
require "rake/testtask"
require_relative "lib/aufgaben/release"
require_relative "lib/aufgaben/version"

task default: :test

Rake::TestTask.new do |t|
  t.libs << "test"
  t.test_files = FileList["test/**/*_test.rb"]
  t.verbose = true
end

Aufgaben::Release.new(:release_new) do |t|
  t.new_version = Aufgaben::VERSION
end
