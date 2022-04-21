require_relative "./base"
require "json"

module Aufgaben
  class Bump::Ruby < Bump::Base
    DEFAULT_FILES = %w[
      .ruby-version
      Dockerfile
    ].freeze

    DEFAULT_RELEASE_NOTE_URL = "https://www.ruby-lang.org/en/news".freeze
    RELEASE_NOTE_URLS = JSON.parse(File.read(File.join(__dir__, "..", "..", "ruby_release_urls.json")), symbolize_names: true).freeze

    def initialize(name = :ruby, ns = default_namespace, depends: [])
      self.files = DEFAULT_FILES.dup
      self.current_version = RUBY_VERSION

      super(name, ns, "Ruby", depends: depends)
    end

    private

    def release_label
      "release note"
    end

    def release_url
      RELEASE_NOTE_URLS.fetch(next_version.to_sym, DEFAULT_RELEASE_NOTE_URL)
    end
  end
end
