require "rake"
require "rake/tasklib"

module Aufgaben
  class Base < ::Rake::TaskLib
    attr_reader :name
    attr_reader :depends
    attr_accessor :dry_run

    def initialize(name, depends:)
      super()
      @name = name
      @depends = depends
      @dry_run = false
    end

    def dry_run?
      ENV["DRY_RUN"] || dry_run
    end

    def git(*cmd, &block)
      sh("git", *cmd, &block)
    end
  end
end
