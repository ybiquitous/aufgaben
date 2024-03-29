require_relative "base"
require_relative "color"

module Aufgaben
  class Release < Base
    attr_accessor :default_branch
    attr_accessor :changelog
    attr_accessor :files
    attr_accessor :new_version

    def initialize(name = :release, depends: [])
      super(name, depends: depends)
      @default_branch = "main"
      @changelog = "CHANGELOG.md"
      @files = []
      @new_version = nil

      yield self if block_given?
      define
    end

    private

    def define
      desc "Perform a release work"
      task name, [:version] => depends do |_task, args|
        self.new_version = args[:version] if args[:version]

        unless new_version
          abort "Specify a new version. Usage: rake #{name}[version]"
        end

        msg "Start releasing..."

        msg "If you want to do this on dry-run mode, set 'DRY_RUN=1'." unless dry_run?

        git "checkout", default_branch, "--quiet"
        git "pull", "origin", default_branch, "--quiet"
        sh "bundle", "install", "--quiet"

        if current_version.empty?
          initial = true
        else
          initial = false
          unless Gem::Version.new(current_version) < Gem::Version.new(new_version)
            abort "Invalid version! current=#{current_version} new=#{new_version}"
          end
        end

        git "diff", "--exit-code", "--quiet" do |ok|
          abort "Uncommitted changes found!" unless ok
        end

        if initial
          msg "Releasing a new version: #{colored_new_version}"
        else
          msg "Releasing a new version: #{current_version} -> #{colored_new_version}"
        end

        git "--no-pager", "log", "--format=%C(auto)%h %Creset%s", "#{current_version}..HEAD"

        each_file do |file|
          update_version_in file, write: false
        end

        if dry_run?
          msg "This is a dry-run mode. No actual changes. Next, run this without `DRY_RUN=1`."
        else
          if interactive?
            answer_yes? or abort "Aborted."
          end

          if File.exist? changelog
            update_changelog from: current_version, to: new_version
          else
            add_changelog with: new_version
          end
          git "add", changelog

          each_file do |file|
            update_version_in file
            git "add", file
          end

          git "commit", "--quiet", "--message", "Version #{new_version}"
          git "tag", "--annotate", "--message", "Version #{new_version}", new_version
          git "show", "--pretty"

          check_committed_files

          git_push = Color.new("git push --follow-tags").green
          msg "The tag '#{colored_new_version}' is added. Run '#{git_push}'."
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

    def check_committed_files
      expected = [*expanded_files, changelog].sort
      actual = `git diff --name-only HEAD^...HEAD`.lines(chomp: true).sort

      if expected != actual
        abort <<~MSG
          The committed files are not what was expected.
          Expected: #{expected}
          Actual:   #{actual}
        MSG
      end
    end

    def expanded_files
      @expanded_files ||= Dir.glob(files, File::FNM_EXTGLOB)
    end

    def each_file(&block)
      expanded_files.each(&block)
    end

    def update_version_in(file, write: true)
      content = File.read(file)

      current_version_pattern = Regexp.new('\b' + Regexp.escape(current_version) + '\b')
      unless current_version_pattern.match?(content)
        abort "The current version '#{current_version}' is not found in '#{file}'!"
      end

      new_content = content.gsub(current_version_pattern, new_version)
      if content == new_content
        abort "No changes in '#{file}'"
      end

      if write
        File.write(file, new_content)
        msg "'#{file}' is updated."
      end
    end

    def msg(text)
      puts
      puts "> #{text}"
      puts
    end

    def interactive?
      !ENV["NONINTERACTIVE"]
    end

    def answer_yes?
      puts
      loop do
        print "> Perform the release of version #{colored_new_version}? [y/N] "
        answer = STDIN.gets.chomp.downcase
        if answer == "y"
          return true
        elsif answer == "n" || answer == ""
          return false
        else
          puts "> Please type 'y' or 'n'."
          next
        end
      end
    end

    def colored_new_version
      Color.new(new_version).green
    end
  end
end
