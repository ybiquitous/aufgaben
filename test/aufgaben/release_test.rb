require "test_helper"
require_relative "../../lib/aufgaben/release"

class ReleaseTest < Minitest::Test
  include TestHelper

  def test_normal_case
    in_tmpdir do |basedir, workdir, git_remote_path, default_branch|
      prepare_gemfile basedir, workdir

      (workdir / "Rakefile").write <<~CONTENT
        require "aufgaben/release"
        Aufgaben::Release.new
      CONTENT

      (workdir / "CHANGELOG.md").write <<~CONTENT
        # Changelog

        All notable changes to this project will be documented in this file.

        ## Unreleased

        [Full diff](https://example-git.com/foo/bar/compare/1.0.0...HEAD)
      CONTENT

      init_git_repo! git_remote_path, default_branch

      sh! "git", "add", "."
      sh! "git", "commit", "-m", "Init"
      sh! "git", "tag", "-a", "1.0.0", "-m", "Version 1.0.0"
      sh! "git", "push", "--follow-tags"

      sh! "rake", "release[1.1.0]", "NONINTERACTIVE=1"
      sh! "git", "push", "--follow-tags"

      stdout, = sh! "git", "show"
      assert_match "Version 1.1.0", stdout

      stdout, = sh! "git", "ls-remote", "--tags"
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
    in_tmpdir do |basedir, workdir, git_remote_path, default_branch|
      prepare_gemfile basedir, workdir

      (workdir / "Rakefile").write <<~CONTENT
        require "aufgaben/release"
        Aufgaben::Release.new
      CONTENT

      init_git_repo! git_remote_path, default_branch

      sh! "git", "add", "."
      sh! "git", "commit", "-m", "Init"
      sh! "git", "push"

      sh! "rake", "release[1.0.0]", "NONINTERACTIVE=1", env: { "AUFGABEN_GIT_REMOTE_COMMAND" => "echo 'origin git@github.com:user/repo.git (push)'" }
      sh! "git", "push", "--follow-tags"

      stdout, = sh! "git", "show"
      assert_match "Version 1.0.0", stdout

      stdout, = sh! "git", "ls-remote", "--tags"
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
    in_tmpdir do |basedir, workdir, git_remote_path, default_branch|
      prepare_gemfile basedir, workdir

      (workdir / "Rakefile").write <<~CONTENT
        require "aufgaben/release"
        Aufgaben::Release.new
      CONTENT

      init_git_repo! git_remote_path, default_branch

      sh! "git", "add", "."
      sh! "git", "commit", "-m", "Init"
      sh! "git", "tag", "-a", "1.0.0", "-m", "Version 1.0.0"
      sh! "git", "push", "--follow-tags"

      before = sh! "git", "show", "--format=short"
      sh! "rake", "release[2.0.0]", "DRY_RUN=1"
      after = sh! "git", "show", "--format=short"

      assert_equal before, after
    end
  end

  def test_update_files
    in_tmpdir do |basedir, workdir, git_remote_path, default_branch|
      prepare_gemfile basedir, workdir

      (workdir / "Rakefile").write <<~RUBY
        require "aufgaben/release"
        Aufgaben::Release.new do |t|
          t.files = ["version.rb", "*.{a,b}"]
        end
      RUBY

      (workdir / "version.rb").write <<~RUBY
        version = "0.9.1"
        version = "foo 0.9.1 bar"
      RUBY

      (workdir / "test.a").write "a = 0.9.1"
      (workdir / "test.b").write "b = 0.9.1"

      init_git_repo! git_remote_path, default_branch

      sh! "git", "add", "."
      sh! "git", "commit", "-m", "Init"
      sh! "git", "tag", "-a", "0.9.1", "-m", "Version 0.9.1"
      sh! "git", "push", "--follow-tags"

      sh! "rake", "release[1.3.5]", "NONINTERACTIVE=1", env: { "AUFGABEN_GIT_REMOTE_COMMAND" => "echo 'origin git@github.com:user/repo.git (push)'" }

      stdout, _ = sh! "git", "show", "--stat"
      assert_match "version.rb", stdout
      assert_match "test.a", stdout
      assert_match "test.b", stdout

      assert_equal <<~RUBY, (workdir / "version.rb").read
        version = "1.3.5"
        version = "foo 1.3.5 bar"
      RUBY
      assert_equal "a = 1.3.5", (workdir / "test.a").read
      assert_equal "b = 1.3.5", (workdir / "test.b").read
    end
  end

  def test_no_current_version_in_version_file
    in_tmpdir do |basedir, workdir, git_remote_path, default_branch|
      (workdir / "Rakefile").write <<~RUBY
        require "aufgaben/release"
        Aufgaben::Release.new do |t|
          t.files = ["version.rb"]
        end
      RUBY

      (workdir / "version.rb").write <<~RUBY
        version = "0.0.9"
      RUBY

      init_git_repo! git_remote_path, default_branch

      sh! "git", "add", "."
      sh! "git", "commit", "-m", "Init"
      sh! "git", "tag", "-a", "1.0.0", "-m", "Version 1.0.0"
      sh! "git", "push", "--follow-tags"

      _stdout, stderr, status = sh! "rake", "release[1.1.0]", error: false

      assert_match %r{^The current version '1\.0\.0' is not found in 'version\.rb'!$}, stderr
      assert_equal 1, status.exitstatus
    end
  end

  def test_depends
    in_tmpdir git: false do |basedir, workdir|
      prepare_gemfile basedir, workdir

      (workdir / "Rakefile").write <<~RUBY
        require "aufgaben/release"
        Aufgaben::Release.new(:foo, depends: [:test])
        task :test
      RUBY

      _, stderr, _ = sh! "rake", "foo[1.0]", "--dry-run"
      assert_includes stderr, "Invoke foo"
      assert_includes stderr, "Invoke test"
    end
  end

  def test_no_version
    in_tmpdir git: false do |basedir, workdir|
      prepare_gemfile basedir, workdir

      (workdir / "Rakefile").write <<~RUBY
        require "aufgaben/release"
        Aufgaben::Release.new
      RUBY

      stdout, stderr, status = sh! "rake", "release", error: false
      assert_empty stdout
      assert_equal "Specify a new version. Usage: rake release[version]\n", stderr
      assert_equal 1, status.exitstatus
    end
  end

  private

  def init_git_repo!(remote_path, default_branch)
    sh! "git", "init", "--initial-branch=#{default_branch}"
    sh! "git", "config", "push.default", "current"
    sh! "git", "remote", "add", "origin", remote_path
  end

  def prepare_gemfile(basedir, workdir)
    (workdir / "Gemfile").write <<~CONTENT
      source "https://rubygems.org"
      gem "aufgaben", path: "#{basedir}"
    CONTENT
  end
end
