require "erb"

require_relative "../bump"
require_relative "../base"

module Aufgaben
  class Bump::Ruby < Base
    DEFAULT_FILES = %w[
      .ruby-version
      Dockerfile
    ].freeze

    DEFAULT_COMMIT_MESSAGE_TEMPLATE = <<~'MSG'.freeze
      Bump Ruby from <%= current_version %> to <%= next_version %>

      Via:
      ```
      $ rake <%= ns %>:<%= name %>'[<%= next_version %>]'
      ```

      See <%= release_note_url %>
    MSG

    DEFAULT_RELEASE_NOTE_URL = "https://www.ruby-lang.org/en/news".freeze
    RELEASE_NOTE_URLS = {
      "2.7.1": "https://www.ruby-lang.org/en/news/2020/03/31/ruby-2-7-1-released/",
      "2.7.0": "https://www.ruby-lang.org/en/news/2019/12/25/ruby-2-7-0-released/",
      "2.6.6": "https://www.ruby-lang.org/en/news/2020/03/31/ruby-2-6-6-released/",
      "2.6.5": "https://www.ruby-lang.org/en/news/2019/10/01/ruby-2-6-5-released/",
      "2.6.4": "https://www.ruby-lang.org/en/news/2019/08/28/ruby-2-6-4-released/",
      "2.6.3": "https://www.ruby-lang.org/en/news/2019/04/17/ruby-2-6-3-released/",
      "2.6.2": "https://www.ruby-lang.org/en/news/2019/03/13/ruby-2-6-2-released/",
      "2.6.1": "https://www.ruby-lang.org/en/news/2019/01/30/ruby-2-6-1-released/",
      "2.6.0": "https://www.ruby-lang.org/en/news/2018/12/25/ruby-2-6-0-released/",
    }.freeze

    attr_reader :name
    attr_reader :ns
    attr_accessor :files
    attr_accessor :current_version
    attr_accessor :commit_message_template

    def initialize(name = :ruby, ns = :bump)
      super(name)
      @ns = ns
      @files = DEFAULT_FILES.dup
      @current_version = RUBY_VERSION
      @commit_message_template = DEFAULT_COMMIT_MESSAGE_TEMPLATE

      yield self if block_given?
      namespace(ns) { define }
    end

    private

    attr_reader :next_version

    def define
      desc "Bump Ruby version"
      task name, [:next_version] do |_task, args|
        @next_version = args.fetch(:next_version)

        puts "Bumping Ruby from #{current_version} to #{next_version} ..."
        puts ""

        current_version_pattern = Regexp.new('\b' + Regexp.escape(current_version) + '\b')

        changed_files = files.each_with_object([]) do |file, new_files|
          next unless File.exist? file

          if dry_run?
            puts "#{file} will be changed."
          else
            print "Writing #{file} ..."
            content = File.read(file)
            content.gsub!(current_version_pattern, next_version)
            File.write(file, content)
            puts " OK"
            puts ""
          end

          new_files << file
        end

        if changed_files.empty?
          puts "No changed files."
        elsif !dry_run?
          puts "Committing changed files ..."
          puts ""
          sh "git", "add", *changed_files
          sh "git", "commit", "-m", commit_message
        end
      end
    end

    def commit_message
      ERB.new(commit_message_template).result_with_hash(
        ns: ns,
        name: name,
        current_version: current_version,
        next_version: next_version,
        release_note_url: RELEASE_NOTE_URLS.fetch(next_version.to_sym, DEFAULT_RELEASE_NOTE_URL)
      )
    end
  end
end
