module Krudmin
  module Generators
    class InstallGenerator < Rails::Generators::Base
      source_root File.expand_path("templates", __dir__)

      desc "Install Krudmin configuration, documentation, and AI agent instructions into your project"

      class_option :docs, type: :boolean, default: true, desc: "Copy documentation files"
      class_option :claude, type: :boolean, default: true, desc: "Generate CLAUDE.md for AI agents"
      class_option :initializer, type: :boolean, default: true, desc: "Generate Krudmin initializer"
      class_option :docs_only, type: :boolean, default: false, desc: "Only update docs/krudmin in the host app"

      def docs_only?
        options[:docs_only]
      end

      def copy_initializer
        return if docs_only?
        return unless options[:initializer]

        template "krudmin_initializer.rb", "config/initializers/krudmin.rb"
      end

      def copy_claude_md
        return if docs_only?
        return unless options[:claude]

        template "CLAUDE.md", "CLAUDE.md"
      end

      def copy_docs
        return unless options[:docs] || docs_only?

        docs_source = File.expand_path("../../../../docs", __dir__)

        %w[
          getting_started.md
          architecture.md
          dashboard.md
          resource_managers.md
          fields.md
          configuration.md
          search_and_filtering.md
          authorization.md
          navigation_menu.md
          views_and_themes.md
          generators.md
        ].each do |doc|
          source_path = File.join(docs_source, doc)
          if File.exist?(source_path)
            copy_file source_path, "docs/krudmin/#{doc}"
          end
        end
      end

      def create_resource_managers_directory
        return if docs_only?

        empty_directory "app/resource_managers"
      end

      def print_post_install
        say ""
        if docs_only?
          say "Krudmin docs updated successfully!", :green
        else
          say "Krudmin installed successfully!", :green
        end
        say ""
        if docs_only?
          say "Updated docs in docs/krudmin/", :cyan
          say ""
          return
        end

        say "Next steps:", :yellow
        say "  1. Edit config/initializers/krudmin.rb to configure your admin panel"
        say "  2. Generate a resource:  rails generate krudmin:resource Product name:string price:decimal active:boolean"
        say "  3. Start your server and visit your admin panel"
        say ""
        if options[:claude]
          say "AI Agent instructions written to CLAUDE.md", :cyan
        end
        if options[:docs]
          say "Documentation copied to docs/krudmin/", :cyan
        end
      end
    end
  end
end
