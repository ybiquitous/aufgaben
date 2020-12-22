require "test_helper"
require_relative "../../../lib/aufgaben/bump/nodejs"

class BumpNodejsTest < Minitest::Test
  include TestHelper

  def run!(arg)
    sh! "git init"
    sh! "git add ."
    sh! "git commit -m 'Init'"
    sh! "rake bump:nodejs[#{arg}]"
  end

  def test_default
    in_tmpdir do
      File.write "Rakefile", <<~RUBY
        require "aufgaben/bump/nodejs"
        Aufgaben::Bump::Nodejs.new
      RUBY
      File.write ".node-version", "12.16.0\n"
      File.write ".nvmrc", "12.16.0\n"
      File.write "Dockerfile", <<~EOF
        FROM node:12.16.0-buster-slim
        RUN node -v
      EOF

      run! "12.16.1"

      assert_equal "12.16.1\n", File.read(".node-version")
      assert_equal "12.16.1\n", File.read(".nvmrc")
      assert_equal <<~EOF, File.read("Dockerfile")
        FROM node:12.16.1-buster-slim
        RUN node -v
      EOF

      stdout, = sh! "git show --pretty=full"
      assert_includes stdout, <<~MSG.gsub(/^/, "    ")
        Bump Node.js from 12.16.0 to 12.16.1

        Via:

        ```console
        $ rake bump:nodejs'[12.16.1]'
        ```

        Read the [changelog](https://github.com/nodejs/node/blob/v12.16.1/doc/changelogs/CHANGELOG_V12.md) for details.
      MSG
    end
  end

  def test_set_version_files
    in_tmpdir do
      File.write "Rakefile", <<~RUBY
        require "aufgaben/bump/nodejs"
        Aufgaben::Bump::Nodejs.new do |t|
          t.version_files << "nodejs-version.txt"
        end
      RUBY
      File.write "nodejs-version.txt", "12.16.0\n"
      File.write "Dockerfile", <<~EOF
        FROM node:12.16.0
        RUN node -v
      EOF

      run! "12.16.1"

      assert_equal "12.16.1\n", File.read("nodejs-version.txt")
      assert_equal <<~EOF, File.read("Dockerfile")
        FROM node:12.16.1
        RUN node -v
      EOF
    end
  end

  def test_depends
    in_tmpdir git: false do
      File.write "Rakefile", <<~RUBY
        require "aufgaben/bump/nodejs"
        Aufgaben::Bump::Nodejs.new(:foo, :node, depends: [:test])
        task :test
      RUBY

      _, stderr, _ = sh! "rake node:foo --dry-run"
      assert_includes stderr, "Invoke node:foo"
      assert_includes stderr, "Invoke test"
    end
  end
end
