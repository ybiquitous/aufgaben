require "rake"
require "rake/tasklib"

module Aufgaben
  class Release < ::Rake::TaskLib
    attr_accessor :name
    attr_accessor :default_branch
    attr_accessor :dry_run
    attr_accessor :changelog

    def initialize(name = :release)
      @name = name
      @default_branch = "master"
      @dry_run = false
      @changelog = "CHANGELOG.md"

      yield self if block_given?
      define
    end

    private

    def dry_run?
      ENV["DRY_RUN"] || dry_run
    end

    def define
      desc "Perform a release work"
      task name, [:version] do |_task, args|
        new_version = args[:version] or abort "Required version!"

        msg "If you want to do this on dry-run mode, set `DRY_RUN=1`." unless dry_run?

        sh "git checkout #{default_branch} --quiet"
        sh "git pull origin #{default_branch} --quiet"
        sh "bundle install --quiet"

        current_version = `git describe --abbrev=0 --tags`.chomp
        unless Gem::Version.new(current_version) < Gem::Version.new(new_version)
          abort "Invalid version! current=#{current_version} new=#{new_version}"
        end

        sh "git diff --exit-code --quiet" do |ok|
          abort "Uncommitted changes found!" unless ok
        end

        sh "git --no-pager log --oneline #{current_version}...HEAD"

        if dry_run?
          msg "This is a dry-run mode. No actual changes."
        else
          update_changelog current_version, new_version
          sh "git commit -a -m 'Version #{new_version}' --quiet"
          sh "git tag -a #{new_version} -m 'Version #{new_version}'"
          msg "The tag '#{new_version}' is added. Run 'git push --follow-tags'."
        end
      end
    end

    def update_changelog(current_version, new_version)
      compare_url = nil
      new_lines = File.readlines(changelog, chomp: true).map do |line|
        case
        when line == "## Unreleased"
          "## #{new_version}"
        when line.include?("#{current_version}...HEAD")
          line.match(%r{\((?<url>.+)/#{current_version}...HEAD\)}) do |m|
            compare_url = m[:url]
          end
          line.sub("#{current_version}...HEAD", "#{current_version}...#{new_version}")
        else
          line
        end
      end
      new_lines.insert(
        4,
        "## Unreleased",
        "",
        "[Full diff](#{compare_url}/#{new_version}...HEAD)",
        "",
      )
      File.write(changelog, new_lines.join("\n") + "\n")

      msg "#{changelog} is updated."
    end

    def msg(text)
      puts "> #{text}"
    end
  end
end
