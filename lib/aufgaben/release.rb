require "rake"
require "rake/tasklib"

module Aufgaben
  class Release < ::Rake::TaskLib
    attr_accessor :name
    attr_accessor :default_branch
    attr_accessor :dry_run

    def initialize(name = :release)
      @name = name
      @default_branch = "master"
      @dry_run = false

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

        puts "If you want a dry-run mode, set `DRY_RUN=1`." unless dry_run?

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
          puts "This is a dry-run mode. No actual changes."
        else
          update_changelog current_version, new_version
          sh "git commit -a -m 'Version #{new_version}' --quiet"
          sh "git tag -a #{new_version} -m 'Version #{new_version}'"
          puts "The tag '#{new_version}' is added. Run 'git push --follow-tags'."
        end
      end
    end
  end
end
