require "test_helper"

class BumpRubyTest < Minitest::Test
  include TestHelper

  def test_normal_case
    in_tmpdir do
      Pathname("Rakefile").write <<~CONTENT
        require "aufgaben/bump/ruby"
        Aufgaben::Bump::Ruby.new do |t|
          t.current_version = "2.6.4"
        end
      CONTENT

      Pathname(".ruby-version").write "2.6.4\n"

      sh! "git init"
      sh! "git add ."
      sh! "git commit -m 'Init'"
      sh! "rake bump:ruby[2.6.5]"

      assert_equal "2.6.5\n", Pathname(".ruby-version").read

      stdout, = sh! "git show --pretty=full"
      assert_match "Bump Ruby from 2.6.4 to 2.6.5", stdout
      assert_match "$ rake bump:ruby'[2.6.5]'", stdout
      assert_match "See <https://www.ruby-lang.org/en/news>", stdout
    end
  end

  def test_customize_files
    in_tmpdir do
      Pathname("Rakefile").write <<~CONTENT
        require "aufgaben/bump/ruby"
        Aufgaben::Bump::Ruby.new do |t|
          t.files << "my-ruby-version"
          t.current_version = "2.6.4"
        end
      CONTENT

      Pathname("my-ruby-version").write "2.6.4\n"

      sh! "git init"
      sh! "git add ."
      sh! "git commit -m 'Init'"
      sh! "rake bump:ruby[2.6.5]"

      assert_equal "2.6.5\n", Pathname("my-ruby-version").read

      stdout, = sh! "git show --pretty=full"
      assert_match "Bump Ruby from 2.6.4 to 2.6.5", stdout
    end
  end

  def test_dry_run
    in_tmpdir do
      Pathname("Rakefile").write <<~CONTENT
        require "aufgaben/bump/ruby"
        Aufgaben::Bump::Ruby.new do |t|
          t.current_version = "2.6.4"
        end
      CONTENT

      Pathname(".ruby-version").write "2.6.4\n"

      sh! "git init"
      sh! "git add ."
      sh! "git commit -m 'Init'"
      sh! "rake bump:ruby[2.6.5] DRY_RUN=1"

      assert_equal "2.6.4\n", Pathname(".ruby-version").read

      stdout, = sh! "git show --pretty=full"
      assert_match "Init", stdout
    end
  end

  def test_no_changed_files
    in_tmpdir do
      Pathname("Rakefile").write <<~CONTENT
        require "aufgaben/bump/ruby"
        Aufgaben::Bump::Ruby.new do |t|
          t.current_version = "2.6.4"
        end
      CONTENT

      sh! "git init"
      sh! "git add ."
      sh! "git commit -m 'Init'"
      sh! "rake bump:ruby[2.6.5]"

      stdout, = sh! "git show --pretty=full"
      assert_match "Init", stdout
    end
  end
end
