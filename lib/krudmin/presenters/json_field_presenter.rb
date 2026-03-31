module Krudmin
  module Presenters
    class JsonFieldPresenter < BaseFieldPresenter
      def render_list
        return "-" if field.data.nil?

        truncated = field.formatted_value
        truncated.length > 60 ? "#{truncated[0..57]}..." : truncated
      end

      def render_show
        render_partial(:show)
      end
    end
  end
end
