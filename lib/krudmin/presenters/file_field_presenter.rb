module Krudmin
  module Presenters
    class FileFieldPresenter < BaseFieldPresenter
      def render_list
        field.attached? ? field.filename : "-"
      end

      def render_show
        render_partial(:show)
      end

      def render_search; end
    end
  end
end
