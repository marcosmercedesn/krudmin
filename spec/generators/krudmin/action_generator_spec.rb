require_relative "../generator_spec_helper"
require "generators/krudmin/action/action_generator"

RSpec.describe Krudmin::Generators::ActionGenerator do
  include GeneratorSpecHelper

  describe "with default options" do
    before { run_generator %w[generate_invoice] }

    it "creates a button class" do
      expect(file_exists?("lib/krudmin/action_buttons/generate_invoice_button.rb")).to be true

      content = file_content("lib/krudmin/action_buttons/generate_invoice_button.rb")
      expect(content).to include("class GenerateInvoiceButton < ModelActionButton")
      expect(content).to include("def tooltip_title")
    end

    it "creates a list partial" do
      expect(file_exists?("app/views/krudmin/core_theme/action_buttons/generate_invoice_button/_list.html.haml")).to be true
    end

    it "creates a form partial" do
      expect(file_exists?("app/views/krudmin/core_theme/action_buttons/generate_invoice_button/_form.html.haml")).to be true
    end

    it "creates a spec" do
      expect(file_exists?("spec/lib/krudmin/action_buttons/generate_invoice_button_spec.rb")).to be true

      content = file_content("spec/lib/krudmin/action_buttons/generate_invoice_button_spec.rb")
      expect(content).to include("Krudmin::ActionButtons::GenerateInvoiceButton")
      expect(content).to include("ModelActionButton")
    end
  end

  describe "with --no-model-action" do
    before { run_generator %w[generate_invoice --no-model-action] }

    it "creates a button inheriting from Base" do
      content = file_content("lib/krudmin/action_buttons/generate_invoice_button.rb")
      expect(content).to include("class GenerateInvoiceButton < Base")
    end

    it "creates a spec referencing Base" do
      content = file_content("spec/lib/krudmin/action_buttons/generate_invoice_button_spec.rb")
      expect(content).to include("Krudmin::ActionButtons::Base")
    end
  end

  describe "with --no-specs" do
    before { run_generator %w[generate_invoice --no-specs] }

    it "does not create a spec" do
      expect(file_exists?("spec/lib/krudmin/action_buttons/generate_invoice_button_spec.rb")).to be false
    end

    it "still creates the button and partials" do
      expect(file_exists?("lib/krudmin/action_buttons/generate_invoice_button.rb")).to be true
      expect(file_exists?("app/views/krudmin/core_theme/action_buttons/generate_invoice_button/_list.html.haml")).to be true
      expect(file_exists?("app/views/krudmin/core_theme/action_buttons/generate_invoice_button/_form.html.haml")).to be true
    end
  end
end
