module Krudmin
  module ActionButtons
    class CustomActionButton < ModelActionButton
      attr_reader :action_definition

      def initialize(page, view_context, model, action_definition:, html_options: {}, &block)
        @action_definition = action_definition
        super(page, view_context, model, html_options, &block)
      end

      def tooltip_title
        action_definition[:label]
      end

      def action_label
        action_definition[:label]
      end

      def action_icon
        action_definition[:icon]
      end

      def action_method
        action_definition[:method]
      end

      def action_confirm
        action_definition[:confirm]
      end

      def action_css_class
        action_definition[:class] || "btn-outline-primary"
      end

      def turbo?
        action_definition[:turbo]
      end

      def authorize?
        action_definition[:authorize]
      end

      def action_url
        view_context.krudmin_manager.member_action_path(view_context, model, action_definition[:name])
      end

      def visible?(user = nil, context = nil)
        condition = action_definition[:if]
        return true unless condition.respond_to?(:call)

        condition.call(model, user, context)
      end

      def partial_scope
        "custom_action_button"
      end

      def render_list
        return "".html_safe unless visible?

        render_partial(:list, button_locals)
      end

      def render_form
        return "".html_safe unless visible?

        render_partial(:form, button_locals)
      end

      private

      def button_locals
        {
          action_url: action_url,
          action_label: action_label,
          action_icon: action_icon,
          action_method: action_method,
          action_confirm: action_confirm,
          action_css_class: action_css_class,
          turbo: turbo?
        }
      end
    end
  end
end
