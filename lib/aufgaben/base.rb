require "rake"
require "rake/tasklib"

module Aufgaben
  class Base < ::Rake::TaskLib
    attr_reader :name
    attr_accessor :dry_run

    def initialize(name)
      @name = name
      @dry_run = false
    end

    def dry_run?
      ENV["DRY_RUN"] || dry_run
    end
  end
end
