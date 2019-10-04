require "test_helper"

class ReleaseTest < Minitest::Test
  include TestHelper

  def test_normal_case
    in_tmpdir do |basedir, workdir, git_remote_path|
      (workdir / "Rakefile").write <<~CONTENT
        require_relative "#{basedir / 'lib/aufgaben/release'}"
        Aufgaben::Release.new
      CONTENT

      (workdir / "CHANGELOG.md").write <<~CONTENT
        # Changelog

        All notable changes to this project will be documented in this file.

        ## Unreleased

        [Full diff](https://example-git.com/foo/bar/compare/1.0.0...HEAD)
      CONTENT

      (workdir / "Gemfile").write <<~CONTENT
        source "https://rubygems.org"
      CONTENT

      sh! "git init"
      sh! "git remote add origin '#{git_remote_path}'"
      sh! "git add ."
      sh! "git commit -m 'Init'"
      sh! "git tag -a 1.0.0 -m 'Version 1.0.0'"
      sh! "git push --follow-tags origin master"

      sh! "rake release'[1.1.0]'"
      sh! "git push --follow-tags origin master"

      stdout, = sh! "git show"
      assert_match "Version 1.1.0", stdout

      stdout, = sh! "git ls-remote --tags"
      assert_match "refs/tags/1.0.0", stdout
      assert_match "refs/tags/1.1.0", stdout

      assert_equal <<~CONTENT, (workdir / "CHANGELOG.md").read
        # Changelog

        All notable changes to this project will be documented in this file.

        ## Unreleased

        [Full diff](https://example-git.com/foo/bar/compare/1.1.0...HEAD)

        ## 1.1.0

        [Full diff](https://example-git.com/foo/bar/compare/1.0.0...1.1.0)
      CONTENT
    end
  end

  def test_initial_release
    in_tmpdir do |basedir, workdir, git_remote_path|
      (workdir / "Rakefile").write <<~CONTENT
        require_relative "#{basedir / 'lib/aufgaben/release'}"
        Aufgaben::Release.new
      CONTENT

      (workdir / "Gemfile").write <<~CONTENT
        source "https://rubygems.org"
      CONTENT

      sh! "git init"
      sh! "git remote add origin '#{git_remote_path}'"
      sh! "git add ."
      sh! "git commit -m 'Init'"
      sh! "git push origin master"

      sh! "rake release'[1.0.0]'", env: { "AUFGABEN_GIT_REMOTE_COMMAND" => "echo 'origin git@github.com:user/repo.git (push)'" }
      sh! "git push --follow-tags origin master"

      stdout, = sh! "git show"
      assert_match "Version 1.0.0", stdout

      stdout, = sh! "git ls-remote --tags"
      assert_match "refs/tags/1.0.0", stdout

      assert_equal <<~CONTENT, (workdir / "CHANGELOG.md").read
        # Changelog

        All notable changes to this project will be documented in this file.

        ## Unreleased

        [Full diff](https://github.com/user/repo/compare/1.0.0...HEAD)

        ## 1.0.0

        Initial release.
      CONTENT
    end
  end

  def test_dry_run_mode
    in_tmpdir do |basedir, workdir, git_remote_path|
      (workdir / "Rakefile").write <<~CONTENT
        require_relative "#{basedir / 'lib/aufgaben/release'}"
        Aufgaben::Release.new
      CONTENT

      (workdir / "Gemfile").write <<~CONTENT
        source "https://rubygems.org"
      CONTENT

      sh! "git init"
      sh! "git remote add origin '#{git_remote_path}'"
      sh! "git add ."
      sh! "git commit -m 'Init'"
      sh! "git tag -a 1.0.0 -m 'Version 1.0.0'"
      sh! "git push --follow-tags origin master"

      before = sh! "git show --format=short"
      sh! "rake release'[2.0.0]' DRY_RUN=1"
      after = sh! "git show --format=short"

      assert_equal before, after
    end
  end
end
