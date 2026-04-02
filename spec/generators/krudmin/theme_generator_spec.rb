require_relative "../generator_spec_helper"
require "generators/krudmin/theme/theme_generator"

RSpec.describe Krudmin::Generators::ThemeGenerator do
  include GeneratorSpecHelper

  describe "with a theme name" do
    before { run_generator %w[my_theme] }

    it "copies the core theme directory" do
      expect(file_exists?("app/views/krudmin/my_theme")).to be true
    end

    it "copies field partials" do
      expect(file_exists?("app/views/krudmin/my_theme/fields/base/_form_field.html.haml")).to be true
      expect(file_exists?("app/views/krudmin/my_theme/fields/string/_form_field.html.haml")).to be true
    end

    it "copies action button partials" do
      expect(file_exists?("app/views/krudmin/my_theme/action_buttons/edit_button/_list.html.haml")).to be true
    end

    it "copies layout templates" do
      expect(file_exists?("app/views/krudmin/my_theme/index.html.haml")).to be true
      expect(file_exists?("app/views/krudmin/my_theme/show.html.haml")).to be true
    end

    it "copies dashboard widget partials" do
      expect(file_exists?("app/views/krudmin/my_theme/dashboard/widgets/_count.html.haml")).to be true
    end
  end
end
