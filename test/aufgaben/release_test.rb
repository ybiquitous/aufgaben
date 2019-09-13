require "minitest/autorun"
require "rake"
require "pathname"
require "open3"

class ReleaseTest < Minitest::Test
  def test_run_task
    basedir = Pathname.pwd

    git_remote_dir = Dir.mktmpdir
    git_remote_path = Pathname(git_remote_dir) / "remote_repo.git"
    sh! "git init --bare '#{git_remote_path}'"

    Dir.mktmpdir do |dir|
      Dir.chdir dir

      workdir = Pathname(dir)

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
  ensure
    FileUtils.remove_entry git_remote_dir
  end

  def sh!(cmd)
    stdout, stderr, status = Open3.capture3(cmd)
    puts stdout
    puts stderr
    status.success? or raise "Error: #{cmd}"
    [stdout, stderr, status]
  end
end
