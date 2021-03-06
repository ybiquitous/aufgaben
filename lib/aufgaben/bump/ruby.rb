require_relative "./base"

module Aufgaben
  class Bump::Ruby < Bump::Base
    DEFAULT_FILES = %w[
      .ruby-version
      Dockerfile
    ].freeze

    DEFAULT_RELEASE_NOTE_URL = "https://www.ruby-lang.org/en/news".freeze
    RELEASE_NOTE_URLS = {
      "3.0.2": "https://www.ruby-lang.org/en/news/2021/07/07/ruby-3-0-2-released/",
      "3.0.1": "https://www.ruby-lang.org/en/news/2021/04/05/ruby-3-0-1-released/",
      "3.0.0": "https://www.ruby-lang.org/en/news/2020/12/25/ruby-3-0-0-released/",
      "2.7.4": "https://www.ruby-lang.org/en/news/2021/07/07/ruby-2-7-4-released/",
      "2.7.3": "https://www.ruby-lang.org/en/news/2021/04/05/ruby-2-7-3-released/",
      "2.7.2": "https://www.ruby-lang.org/en/news/2020/10/02/ruby-2-7-2-released/",
      "2.7.1": "https://www.ruby-lang.org/en/news/2020/03/31/ruby-2-7-1-released/",
      "2.7.0": "https://www.ruby-lang.org/en/news/2019/12/25/ruby-2-7-0-released/",
      "2.6.8": "https://www.ruby-lang.org/en/news/2021/07/07/ruby-2-6-8-released/",
      "2.6.7": "https://www.ruby-lang.org/en/news/2021/04/05/ruby-2-6-7-released/",
      "2.6.6": "https://www.ruby-lang.org/en/news/2020/03/31/ruby-2-6-6-released/",
      "2.6.5": "https://www.ruby-lang.org/en/news/2019/10/01/ruby-2-6-5-released/",
      "2.6.4": "https://www.ruby-lang.org/en/news/2019/08/28/ruby-2-6-4-released/",
      "2.6.3": "https://www.ruby-lang.org/en/news/2019/04/17/ruby-2-6-3-released/",
      "2.6.2": "https://www.ruby-lang.org/en/news/2019/03/13/ruby-2-6-2-released/",
      "2.6.1": "https://www.ruby-lang.org/en/news/2019/01/30/ruby-2-6-1-released/",
      "2.6.0": "https://www.ruby-lang.org/en/news/2018/12/25/ruby-2-6-0-released/",
    }.freeze

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
