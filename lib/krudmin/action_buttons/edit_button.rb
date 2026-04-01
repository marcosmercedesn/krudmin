module Krudmin
  module ActionButtons
    class EditButton < ModelActionButton
      def tooltip_title
        I18n.t("krudmin.tooltip.edit", label: model_label)
      end

      def remote_support?
        true
      end
    end
  end
end
