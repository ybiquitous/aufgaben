require "bundler/gem_tasks"
require "rake/testtask"

task default: :test

Rake::TestTask.new do |t|
  t.libs << "test"
  t.test_files = FileList["test/**/*_test.rb"]
  t.verbose = true
end

require_relative "lib/aufgaben/release"
Aufgaben::Release.new(:release_new) do |t|
  t.files = ["lib/aufgaben/version.rb"]
end

require_relative "lib/aufgaben/bump/ruby"
Aufgaben::Bump::Ruby.new
