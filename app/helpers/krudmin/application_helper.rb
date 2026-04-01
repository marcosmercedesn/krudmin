module Krudmin
  module ApplicationHelper
    PERSISTED_CSS_BODY_CLASSES = ["sidebar-minimized", "brand-minimized", "sidebar-hidden"].freeze

    def body_classes
      PERSISTED_CSS_BODY_CLASSES.map { |body_class| evaluate_boolean_string(body_class) }.compact.join(" ")
    end

    def render_item_row(item)
      render partial: "list_item", locals: { item: item }
    end

    def inline_edit_data_for(column_label, item)
      field = field_for(column_label, item)
      field_type = field.class.name.demodulize.underscore

      data = {
        inline_edit_url_value: resource_path(item),
        inline_edit_model_key_value: model_class.model_name.param_key,
        inline_edit_attribute_value: column_label,
        inline_edit_field_type_value: field_type,
        inline_edit_field_value_value: field.data
      }

      if field_type == "enum_type"
        data[:inline_edit_field_options_value] = field.associated_options.map { |label, val| { label: label, value: val } }.to_json
      elsif field_type == "belongs_to"
        options = field.associated_options.map { |opt| { label: opt.send(field.collection_label_field), value: opt.id } }
        data[:inline_edit_field_options_value] = options.to_json
      elsif field_type == "boolean"
        data[:inline_edit_field_options_value] = [{ label: I18n.t("krudmin.labels.yes"), value: "true" }, { label: I18n.t("krudmin.labels.no"), value: "false" }].to_json
        data[:inline_edit_field_value_value] = field.data.to_s
      end

      data
    end

    private

    def evaluate_boolean_string(value)
      cookies[value] == "true" ? value : nil
    end
  end
end
