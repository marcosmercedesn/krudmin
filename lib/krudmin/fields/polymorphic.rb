require_relative "../presenters/polymorphic_field_presenter"

module Krudmin
  module Fields
    class Polymorphic < Base
      PRESENTER = Krudmin::Presenters::PolymorphicFieldPresenter

      def association_name
        @association_name ||= options.fetch(:association_name) { attribute.to_s.chomp("_type").to_sym }
      end

      def type_attribute
        @type_attribute ||= "#{association_name}_type".to_sym
      end

      def id_attribute
        @id_attribute ||= "#{association_name}_id".to_sym
      end

      def type_value
        model&.send(type_attribute)
      end

      def id_value
        model&.send(id_attribute)
      end

      def associated_record
        return nil unless type_value.present? && id_value.present?

        @associated_record ||= model.send(association_name)
      rescue NoMethodError
        nil
      end

      def type_options
        @type_options ||= options.fetch(:type_options, [])
      end

      def type_options_for_select
        type_options.map do |klass_name|
          [klass_name.to_s.underscore.humanize, klass_name.to_s]
        end
      end

      def label_method
        options.fetch(:label_method, :to_s)
      end

      def to_s
        if associated_record
          associated_record.send(label_method)
        elsif type_value.present?
          "#{type_value} ##{id_value}"
        else
          "-"
        end
      end

      def permitted_attribute
        [type_attribute, id_attribute]
      end

      def self.type_as_hash(attribute, options)
        association_name = options.fetch(:association_name) { attribute.to_s.chomp("_type").to_sym }
        {
          :"#{association_name}_type" => options,
          :"#{association_name}_id" => options,
        }
      end
    end
  end
end
