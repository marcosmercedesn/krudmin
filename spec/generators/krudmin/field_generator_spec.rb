require_relative "../generator_spec_helper"
require "generators/krudmin/field/field_generator"

RSpec.describe Krudmin::Generators::FieldGenerator do
  include GeneratorSpecHelper

  describe "with default options" do
    before { run_generator %w[Phone] }

    it "creates a field class" do
      expect(file_exists?("lib/krudmin/fields/phone.rb")).to be true

      content = file_content("lib/krudmin/fields/phone.rb")
      expect(content).to include("class Phone < Base")
      expect(content).to include("PRESENTER = Krudmin::Presenters::PhoneFieldPresenter")
      expect(content).to include('require_relative "../presenters/phone_field_presenter"')
    end

    it "creates a presenter class" do
      expect(file_exists?("lib/krudmin/presenters/phone_field_presenter.rb")).to be true

      content = file_content("lib/krudmin/presenters/phone_field_presenter.rb")
      expect(content).to include("class PhoneFieldPresenter < BaseFieldPresenter")
    end

    it "creates a form partial" do
      expect(file_exists?("app/views/krudmin/core_theme/fields/phone/_form_field.html.haml")).to be true
    end

    it "creates a search partial" do
      expect(file_exists?("app/views/krudmin/core_theme/fields/phone/_search.html.haml")).to be true
    end

    it "creates a spec" do
      expect(file_exists?("spec/lib/krudmin/fields/phone_spec.rb")).to be true

      content = file_content("spec/lib/krudmin/fields/phone_spec.rb")
      expect(content).to include("describe Krudmin::Fields::Phone")
      expect(content).to include("Krudmin::Fields::Base")
    end
  end

  describe "with --parent=String" do
    before { run_generator %w[Phone --parent=String] }

    it "creates a field inheriting from the specified parent" do
      content = file_content("lib/krudmin/fields/phone.rb")
      expect(content).to include("class Phone < String")
    end

    it "creates a spec referencing the parent" do
      content = file_content("spec/lib/krudmin/fields/phone_spec.rb")
      expect(content).to include("Krudmin::Fields::String")
      expect(content).to include('require "#{Dir.pwd}/lib/krudmin/fields/string"')
    end
  end

  describe "with --no-specs" do
    before { run_generator %w[Phone --no-specs] }

    it "does not create a spec" do
      expect(file_exists?("spec/lib/krudmin/fields/phone_spec.rb")).to be false
    end

    it "still creates the field and presenter" do
      expect(file_exists?("lib/krudmin/fields/phone.rb")).to be true
      expect(file_exists?("lib/krudmin/presenters/phone_field_presenter.rb")).to be true
    end
  end
end
