module Krudmin
  module Config
    class << self
      def with
        yield(self)

        after_config_received

        self
      end

      def after_config_received
      end

      attr_writer :navigation_menu, :parent_controller, :krudmin_root_path, :pundit_enabled, :theme, :layout, :paginator_position
      attr_writer :audit_enabled, :audit_backend, :audit_recorder, :audit_entries_provider
      attr_accessor :audit_excluded_attributes
      attr_accessor :form_wrapper, :modal_form_wrapper
      attr_accessor :require_authenticated_user_method
      attr_accessor :login_screen_intro_message

      attr_accessor :edit_profile_path, :logout_path

      DEFAULT_CURRENT_USER = proc { }

      DEFAULT_PARENT_CONTROLLER_CLASS = "ActionController::Base"

      DEFAULT_ROOT_PATH = "#"

      DEFAULT_THEME = "krudmin/core_theme"

      DEFAULT_PAGINATOR_POSITION = :top

      DEFAULT_AUDIT_BACKEND = :custom

      DEFAULT_AUDIT_RECORDER = proc { |_payload| }

      DEFAULT_AUDIT_ENTRIES_PROVIDER = proc { |_record, _context| [] }

      def krudmin_root_path
        @krudmin_root_path || DEFAULT_ROOT_PATH
      end

      def parent_controller
        @parent_controller || DEFAULT_PARENT_CONTROLLER_CLASS
      end

      def current_user_method(&block)
        @current_user = block if block
        @current_user || DEFAULT_CURRENT_USER
      end

      def pundit_enabled?
        @pundit_enabled
      end

      def navigation_menu
        @_nav_menu = (@navigation_menu || -> { Krudmin::NavigationMenu.new }).call
      end

      def theme
        @theme || DEFAULT_THEME
      end

      def layout
        @layout || theme
      end

      def paginator_position
        @paginator_position || DEFAULT_PAGINATOR_POSITION
      end

      def audit_enabled?
        !!@audit_enabled
      end

      def audit_backend
        (@audit_backend || DEFAULT_AUDIT_BACKEND).to_sym
      end

      def audit_recorder
        @audit_recorder || DEFAULT_AUDIT_RECORDER
      end

      def audit_entries_provider
        @audit_entries_provider || DEFAULT_AUDIT_ENTRIES_PROVIDER
      end

      def audit_excluded_attributes
        @audit_excluded_attributes || %i[updated_at created_at]
      end

      def audit_backend_instance
        @audit_backend_instance ||= resolve_audit_backend
      end

      def reset_audit_backend!
        @audit_backend_instance = nil
      end

      private

      def resolve_audit_backend
        return Krudmin::Audit::NullBackend.new unless audit_enabled?

        case audit_backend
        when :krudmin
          Krudmin::Audit::KrudminBackend.new
        when :paper_trail
          Krudmin::Audit::PaperTrailBackend.new
        when :custom
          Krudmin::Audit::CustomBackend.new
        else
          if audit_backend.is_a?(Class)
            audit_backend.new
          else
            Krudmin::Audit::NullBackend.new
          end
        end
      end
    end
  end
end
