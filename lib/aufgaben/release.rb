require_relative "base"

module Aufgaben
  class Release < Base
    attr_reader :name
    attr_accessor :default_branch
    attr_accessor :changelog
    attr_accessor :files
    attr_accessor :new_version

    def initialize(name = :release)
      super(name)
      @default_branch = "master"
      @changelog = "CHANGELOG.md"
      @files = []
      @new_version = nil

      yield self if block_given?
      define
    end

    private

    def define
      desc "Perform a release work"
      task name, [:version] do |_task, args|
        self.new_version = args[:version] if args[:version]

        abort "Required a new version!" unless new_version

        msg "Start releasing..."

        msg "If you want to do this on dry-run mode, set 'DRY_RUN=1'." unless dry_run?

        sh "git", "checkout", default_branch, "--quiet"
        sh "git", "pull", "origin", default_branch, "--quiet"
        sh "bundle", "install", "--quiet"

        if current_version.empty?
          initial = true
        else
          initial = false
          unless Gem::Version.new(current_version) < Gem::Version.new(new_version)
            abort "Invalid version! current=#{current_version} new=#{new_version}"
          end
        end

        sh "git", "diff", "--exit-code", "--quiet" do |ok|
          abort "Uncommitted changes found!" unless ok
        end

        if initial
          msg "Releasing a new version: #{new_version}"
        else
          msg "Releasing a new version: #{current_version} -> #{new_version}"
        end

        sh "git", "--no-pager", "log", "--format=%C(auto)%h %Creset%s", "#{current_version}..HEAD"

        if dry_run?
          msg "This is a dry-run mode. No actual changes. Next, run this without `DRY_RUN=1`."
        else
          if File.exist? changelog
            update_changelog from: current_version, to: new_version
          else
            add_changelog with: new_version
          end
          sh "git", "add", changelog

          Dir.glob(files, File::FNM_EXTGLOB).each do |file|
            update_version_in file
            sh "git", "add", file
          end

          sh "git", "commit", "--quiet", "--message", "Version #{new_version}"
          sh "git", "tag", "--annotate", "--message", "Version #{new_version}", new_version
          msg "The tag '#{new_version}' is added. Run 'git push --follow-tags'."
        end
      end
    end

    def current_version
      @current_version ||= `git describe --abbrev=0 --tags`.chomp
    end

    def update_changelog(from:, to:)
      compare_url = nil
      new_lines = File.readlines(changelog, chomp: true).map do |line|
        case
        when line == "## Unreleased"
          "## #{to}"
        when line.include?("#{from}...HEAD")
          line.match(%r{\((?<url>.+)/#{from}...HEAD\)}) do |m|
            compare_url = m[:url]
          end
          line.sub("#{from}...HEAD", "#{from}...#{to}")
        else
          line
        end
      end
      new_lines.insert(
        4,
        "## Unreleased",
        "",
        "[Full diff](#{compare_url}/#{to}...HEAD)",
        "",
      )
      File.write(changelog, new_lines.join("\n") + "\n")

      msg "'#{changelog}' is updated."
    end

    def add_changelog(with:)
      # for test only
      git_remote_command = ENV["AUFGABEN_GIT_REMOTE_COMMAND"] || "git remote --verbose"

      repo = nil
      `#{git_remote_command}`.lines(chomp: true).each do |line|
        line.match(%r{git@github\.com:([^/]+/[^/]+)\.git}) do |m|
          repo = m.captures.first
          break
        end
        line.match(%r{https://github\.com/([^/]+/[^/]+)\.git}) do |m|
          repo = m.captures.first
          break
        end
      end

      abort "No remote repositories on GitHub!" unless repo

      File.write(changelog, <<~CONTENT, encoding: Encoding::UTF_8)
        # Changelog

        All notable changes to this project will be documented in this file.

        ## Unreleased

        [Full diff](https://github.com/#{repo}/compare/#{with}...HEAD)

        ## #{with}

        Initial release.
      CONTENT

      msg "'#{changelog}' is added."
    end

    def update_version_in(file)
      content = File.read(file)
      content = content.gsub(Regexp.new('\b' + Regexp.escape(current_version) + '\b'), new_version)
      File.write(file, content)

      msg "'#{file}' is updated."
    end

    def msg(text)
      puts
      puts "> #{text}"
      puts
    end
  end
end
