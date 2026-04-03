require_relative "../generator_spec_helper"
require "generators/krudmin/install/install_generator"

RSpec.describe Krudmin::Generators::InstallGenerator do
  include GeneratorSpecHelper

  describe "with default options" do
    before { run_generator }

    it "creates initializer, CLAUDE.md, docs, and resource manager directory" do
      expect(file_exists?("config/initializers/krudmin.rb")).to be true
      expect(file_exists?("CLAUDE.md")).to be true
      expect(file_exists?("docs/krudmin/getting_started.md")).to be true
      expect(file_exists?("app/resource_managers")).to be true
    end
  end

  describe "with --docs-only" do
    before { run_generator %w[--docs-only] }

    it "copies docs only" do
      expect(file_exists?("docs/krudmin/getting_started.md")).to be true
      expect(file_exists?("config/initializers/krudmin.rb")).to be false
      expect(file_exists?("CLAUDE.md")).to be false
      expect(file_exists?("app/resource_managers")).to be false
    end
  end
end
