require "test_helper"

class ReleaseTest < Minitest::Test
  include TestHelper

  def prepare_gemfile(basedir, workdir)
    (workdir / "Gemfile").write <<~CONTENT
      source "https://rubygems.org"
      gem "aufgaben", path: "#{basedir}"
    CONTENT
  end

  def test_normal_case
    in_tmpdir do |basedir, workdir, git_remote_path|
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
      prepare_gemfile basedir, workdir

      (workdir / "Rakefile").write <<~CONTENT
        require "aufgaben/release"
        Aufgaben::Release.new
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
      prepare_gemfile basedir, workdir

      (workdir / "Rakefile").write <<~CONTENT
        require "aufgaben/release"
        Aufgaben::Release.new
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

  def test_update_files
    in_tmpdir do |basedir, workdir, git_remote_path|
      prepare_gemfile basedir, workdir

      (workdir / "Rakefile").write <<~RUBY
        require "aufgaben/release"
        Aufgaben::Release.new do |t|
          t.files = ["version.rb"]
        end
      RUBY

      (workdir / "version.rb").write <<~RUBY
        version = "0.9.1"
        version = "foo 0.9.1 bar"
      RUBY

      sh! "git init"
      sh! "git remote add origin '#{git_remote_path}'"
      sh! "git add ."
      sh! "git commit -m 'Init'"
      sh! "git tag -a 0.9.1 -m 'Version 0.9.1'"
      sh! "git push --follow-tags origin master"

      sh! "rake release'[1.3.5]'", env: { "AUFGABEN_GIT_REMOTE_COMMAND" => "echo 'origin git@github.com:user/repo.git (push)'" }

      stdout, _ = sh! "git show --stat"
      assert_match "version.rb", stdout

      assert_equal <<~RUBY, (workdir / "version.rb").read
        version = "1.3.5"
        version = "foo 1.3.5 bar"
      RUBY
    end
  end
end
