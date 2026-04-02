require "spec_helper"
require "rails/generators"
require "fileutils"
require "tmpdir"

module GeneratorSpecHelper
  def self.included(base)
    base.before do
      @destination_root = Dir.mktmpdir("krudmin_generator_test")
      prepare_destination
    end

    base.after do
      FileUtils.rm_rf(@destination_root) if @destination_root && File.exist?(@destination_root)
    end
  end

  def destination_root
    @destination_root
  end

  def prepare_destination
    FileUtils.mkdir_p(destination_root)
    FileUtils.mkdir_p(File.join(destination_root, "config"))
    File.write(File.join(destination_root, "config/routes.rb"), "Rails.application.routes.draw do\nend\n")
  end

  def run_generator(args = [])
    generator_class = described_class
    # Parse option-style args (--foo=bar, --no-foo) into the options hash
    positional = []
    cli_options = {}
    args.each do |arg|
      if arg.start_with?("--skip-")
        key = arg.sub("--skip-", "").tr("-", "_")
        cli_options[key] = false
      elsif arg.start_with?("--no-")
        key = arg.sub("--no-", "").tr("-", "_")
        cli_options[key] = false
      elsif arg.start_with?("--")
        key, value = arg.sub("--", "").split("=", 2)
        key = key.tr("-", "_")
        cli_options[key] = value || true
      else
        positional << arg
      end
    end

    gen = generator_class.new(positional, cli_options, {destination_root: destination_root})
    capture_output { gen.invoke_all }
  end

  def file_content(path)
    File.read(File.join(destination_root, path))
  end

  def file_exists?(path)
    File.exist?(File.join(destination_root, path))
  end

  private

  def capture_output
    orig_stdout = $stdout
    orig_stderr = $stderr
    $stdout = StringIO.new
    $stderr = StringIO.new
    yield
  ensure
    $stdout = orig_stdout
    $stderr = orig_stderr
  end
end
