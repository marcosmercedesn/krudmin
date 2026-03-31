require_relative "../presenters/json_field_presenter"

module Krudmin
  module Fields
    class Json < Base
      PRESENTER = Krudmin::Presenters::JsonFieldPresenter
      SEARCH_PREDICATES = [:cont, :eq]

      def to_s
        formatted_value
      end

      def value
        data
      end

      def parse(value)
        return value if value.is_a?(Hash) || value.is_a?(Array)
        return nil if value.blank?

        ::JSON.parse(value)
      rescue ::JSON::ParserError
        value
      end

      def formatted_value
        return "-" if data.nil?

        ::JSON.pretty_generate(data)
      rescue ::JSON::GeneratorError
        data.to_s
      end

      def flat_pairs
        return [] unless data.is_a?(Hash)

        data.map { |k, v| [k, v.is_a?(Hash) || v.is_a?(Array) ? ::JSON.generate(v) : v] }
      end

      def editable_as_textarea?
        options.fetch(:textarea, true)
      end

      def rows
        options.fetch(:rows, 8)
      end
    end
  end
end
