require "minitest/autorun"
require "rake"
require "pathname"
require "open3"

module TestHelper
  def sh!(*cmd, env: {})
    cmd = cmd.map { |arg| arg.respond_to?(:to_path) ? arg.to_path : arg }
    stdout, stderr, status = Open3.capture3(env, *cmd)
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
    status.success? or raise "Error: #{cmd.join(' ')}"
    [stdout, stderr, status]
  end

  def in_tmpdir(git: true, default_branch: "master")
    basedir = Pathname(__dir__) / ".."

    Dir.mktmpdir do |git_remote_dir|
      if git
        git_remote_path = Pathname(git_remote_dir) / "remote_repo.git"
        sh! "git", "init", "--bare", "--initial-branch=#{default_branch}", git_remote_path
      end

      Dir.mktmpdir do |workdir|
        workdir = Pathname(workdir)
        Dir.chdir workdir
        if git
          yield basedir, workdir, git_remote_path, default_branch
        else
          yield basedir, workdir
        end
      end
    end
  end
end
