require_relative "./base"

module Aufgaben
  class Bump::Nodejs < Bump::Base
    DEFAULT_FILES = %w[
      Dockerfile
    ].freeze

    DEFAULT_VERSION_FILES = %w[
      .node-version
      .nvmrc
    ].freeze

    attr_accessor :version_files

    def initialize(name = :nodejs, ns = default_namespace)
      self.files = DEFAULT_FILES.dup
      self.version_files = DEFAULT_VERSION_FILES.dup

      super(name, ns, "Node.js")
    end

    private

    def current_version
      @current_version ||= init_current_version
    end

    def init_current_version
      version_files.each do |file|
        next unless File.exist? file
        match = File.read(file).match(/^(\d+\.\d+\.\d+)$/)
        return match.captures[0] if match
      end
    end

    def target_files
      Set.new(files + version_files)
    end

    def release_label
      "changelog"
    end

    def release_url
      major_version = Integer(next_version.match(/^(\d+)\./).captures[0])
      "https://github.com/nodejs/node/blob/v#{next_version}/doc/changelogs/CHANGELOG_V#{major_version}.md"
    end
  end
end
