require_relative "associated_type_resolver"

module Krudmin
  module ResourceManagers
    class AttributeCollection
      class NoPresentationMedatataFound < StandardError; end

      INLINE_EDITABLE_FIELD_TYPES = %w[
        String Text Number Decimal Currency Boolean Date DateTime Email EnumType BelongsTo
      ].freeze

      attr_reader :model, :attributes_metadata, :attributes, :searchable_attributes, :presentation_metadata, :listable_attributes, :displayable_attributes, :inline_editable_attributes, :readonly_attributes
      def initialize(model, attributes_metadata, attributes, listable_attributes, searchable_attributes, displayable_attributes, presentation_metadata, lookup_attributes, inline_editable_attributes = [], readonly_attributes = [])
        @model = model
        @attributes_metadata = attributes_metadata
        @presentation_metadata = presentation_metadata
        @listable_attributes = collection_or_default(listable_attributes)
        @displayable_attributes = collection_or_default(displayable_attributes)
        @searchable_attributes = collection_or_default(searchable_attributes)
        @_lookup_attributes = collection_or_default(lookup_attributes)
        @attributes = collection_or_default(attributes)
        @inline_editable_attributes = inline_editable_attributes
        @readonly_attributes = readonly_attributes
      end

      def inline_editable?(field)
        return false unless inline_editable_attributes.include?(field)

        field_type_name = attribute_for(field).type.name.demodulize
        INLINE_EDITABLE_FIELD_TYPES.include?(field_type_name)
      end

      def collection_or_default(collection)
        collection.any? ? collection : column_names
      end

      def column_names
        @column_names ||= (model.column_names - invisible_columns).map(&:to_sym)
      end

      def grouped_attributes
        @grouped_attributes ||= if attributes.is_a?(Hash)
                                  attributes.reduce({}) do |hash, value|
                                    key = value.first
                                    attributes = value.last
                                    hash[key] = { attributes: attributes }.merge(presentation_metadata.fetch(key) { fail NoPresentationMedatataFound.new("No presentation key found for `#{key}`") })
                                    hash
                                  end
                                else
                                  { general: { attributes: attributes, label: "General" } }
                                end
      end

      def editable_attributes
        @editable_attributes ||= attributes.is_a?(Hash) ? attributes.values.flatten : attributes
      end

      def lookup_attributes
        @lookup_attributes ||= @_lookup_attributes.is_a?(Hash) ? @_lookup_attributes.values.flatten : @_lookup_attributes
      end

      def permitted_attributes
        @permitted_attributes ||= (editable_attributes - readonly_attributes).map do |attribute|
          attribute_for(attribute).permitted_attribute
        end
      end

      def attribute_for(field, root = nil)
        if root
          attribute_types[root].type_as_hash[:__attributes][field]
        else
          attribute_types[field]
        end || Attribute.from_inferred_type(field, find_type_for(field, root))
      end

      def find_type_for(field, root = nil)
        field_name = field.to_s

        source_model = root ? model.reflections[root.to_s]&.klass || model : model

        source_model.columns_hash[field_name]&.type || AssociatedTypeResolver.(field_name, source_model)
      end

      def attribute_types
        @attribute_types ||= attributes_metadata.reduce({}) do |hash, item|
          attribute = item.first

          hash[attribute] = Attribute.from(attribute, item.last)
          hash
        end
      end

      private

      def invisible_columns
        @invisible_columns ||= [model.primary_key, "created_at", "updated_at"]
      end
    end
  end
end
