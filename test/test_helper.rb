require "minitest/autorun"
require "rake"
require "pathname"
require "open3"

module TestHelper
  def sh!(cmd, env: {})
    stdout, stderr, status = Open3.capture3(env, cmd)
    unless stdout.empty?
      puts "STDOUT --------------------"
      puts stdout
      puts "---------------------------"
      puts
    end
    unless stderr.empty?
      puts "STDERR --------------------"
      puts stderr
      puts "---------------------------"
      puts
    end
    status.success? or raise "Error: #{cmd}"
    [stdout, stderr, status]
  end

  def in_tmpdir
    basedir = Pathname(__dir__) / ".."

    Dir.mktmpdir do |git_remote_dir|
      git_remote_path = Pathname(git_remote_dir) / "remote_repo.git"
      sh! "git init --bare '#{git_remote_path}'"

      Dir.mktmpdir do |workdir|
        Dir.chdir workdir
        yield basedir, Pathname(workdir), git_remote_path
      end
    end
  end
end
