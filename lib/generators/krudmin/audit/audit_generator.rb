module Krudmin
  module Generators
    class AuditGenerator < Rails::Generators::Base
      source_root File.expand_path("templates", __dir__)

      desc "Install Krudmin audit trail support (migration + configuration)"

      class_option :backend, type: :string, default: "krudmin",
        desc: "Audit backend: krudmin (built-in DB), paper_trail, or custom"

      def create_migration
        return if options[:backend] == "paper_trail"

        migration_template "create_krudmin_audit_entries.rb.tt",
                           "db/migrate/create_krudmin_audit_entries.rb"
      end

      def inject_config
        initializer_path = "config/initializers/krudmin.rb"

        return unless File.exist?(initializer_path)

        config_snippet = <<~RUBY.indent(2)

          # Audit trail
          config.audit_enabled = true
          config.audit_backend = :#{options[:backend]}
        RUBY

        inject_into_file initializer_path, config_snippet, after: "Krudmin::Config.with do |config|\n"
      end

      def print_post_install
        say ""
        say "Krudmin Audit Trail installed!", :green
        say ""

        if options[:backend] != "paper_trail"
          say "Next steps:", :yellow
          say "  1. Run migrations:  rails db:migrate"
          say "  2. Audit is now enabled — create/update/destroy actions will be tracked"
        else
          say "Using PaperTrail backend. Make sure:", :yellow
          say "  1. paper_trail gem is in your Gemfile"
          say "  2. Models include `has_paper_trail`"
        end

        say ""
        say "To exclude attributes from audit on a per-resource basis:", :cyan
        say "  AUDIT_EXCLUDED_ATTRIBUTES = [:password_digest, :token]"
        say ""
      end

      private

      def migration_template(source, destination)
        migration_number = Time.now.utc.strftime("%Y%m%d%H%M%S")
        template source, File.join(File.dirname(destination), "#{migration_number}_#{File.basename(destination)}")
      end
    end
  end
end
