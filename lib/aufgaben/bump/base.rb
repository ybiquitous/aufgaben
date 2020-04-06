require "erb"
require "set"

require_relative "../base"
require_relative "../bump"

module Aufgaben
  module Bump
    class Base < Aufgaben::Base
      DEFAULT_COMMIT_MESSAGE_TEMPLATE = <<-'MSG'.freeze
Bump <%= target_name %> from <%= current_version %> to <%= next_version %>

Via:

```console
$ rake <%= ns %>:<%= name %>'[<%= next_version %>]'
```

Read the [<%= release_label %>](<%= release_url %>) for details.
MSG

      attr_reader :ns
      attr_accessor :files
      attr_accessor :current_version
      attr_accessor :commit_message_template

      def initialize(name, ns, target_name)
        super(name)

        @ns = ns || default_namespace
        @target_name = target_name
        @files ||= []
        @commit_message_template = DEFAULT_COMMIT_MESSAGE_TEMPLATE

        yield self if block_given?

        namespace(ns) { define }
      end

      def default_namespace
        :bump
      end

      private

      attr_reader :target_name
      attr_accessor :next_version

      def target_files
        Set.new(files)
      end

      def define
        desc "Bump #{target_name} version"
        task name, [:next_version] do |_task, args|
          self.next_version = args.fetch(:next_version) or raise "`next_version is required`"
          current_version or raise "`current_version` is required"

          puts "Bumping #{target_name} from #{current_version} to #{next_version} ..."
          puts ""

          current_version_pattern = Regexp.new('\b' + Regexp.escape(current_version) + '\b')

          changed_files = target_files.each_with_object([]) do |file, new_files|
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
          target_name: target_name,
          current_version: current_version,
          next_version: next_version,
          release_label: release_label,
          release_url: release_url,
        )
      end
    end
  end
end
