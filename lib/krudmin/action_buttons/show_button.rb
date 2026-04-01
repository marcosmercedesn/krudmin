module Krudmin
  module ActionButtons
    class ShowButton < ModelActionButton
      def tooltip_title
        I18n.t("krudmin.tooltip.show", label: model_label)
      end

      def remote_support?
        true
      end
    end
  end
end
