module Krudmin
  module Presenters
    class PolymorphicFieldPresenter < BaseFieldPresenter
      def render_list
        field.to_s
      end

      def render_show
        render_partial(:show)
      end

      def render_search; end
    end
  end
end
