module Krudmin
  module Generators
    class ThemeGenerator < Rails::Generators::NamedBase
      desc "Copy the Krudmin core theme for customization"

      def self.source_root
        File.expand_path("../../../../app/views/krudmin/core_theme", __dir__)
      end

      def copy_theme
        directory ".", "app/views/krudmin/#{file_name}"
      end

      def print_post_install
        say ""
        say "Theme copied to app/views/krudmin/#{file_name}/", :green
        say ""
        say "Update your config/initializers/krudmin.rb:", :yellow
        say ""
        say "  config.theme = \"krudmin/#{file_name}\""
        say "  config.layout = \"krudmin/#{file_name}\""
        say ""
      end
    end
  end
end
