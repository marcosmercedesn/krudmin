require_relative "../presenters/file_field_presenter"

module Krudmin
  module Fields
    class File < Base
      PRESENTER = Krudmin::Presenters::FileFieldPresenter

      def data
        @data ||= model&.send(attribute)
      end

      def attached?
        data.respond_to?(:attached?) ? data.attached? : data.present?
      end

      def filename
        return unless attached?

        if data.respond_to?(:filename)
          data.filename.to_s
        elsif data.respond_to?(:file)
          ::File.basename(data.file.to_s)
        end
      end

      def content_type
        data.content_type if attached? && data.respond_to?(:content_type)
      end

      def image?
        content_type&.start_with?("image/")
      end

      def byte_size
        data.byte_size if attached? && data.respond_to?(:byte_size)
      end

      def to_s
        attached? ? filename : "-"
      end

      def parse(value)
        value
      end

      def permitted_attribute
        if multiple?
          { attribute => [] }
        else
          attribute
        end
      end

      def multiple?
        options.fetch(:multiple, false)
      end

      def direct_upload?
        options.fetch(:direct_upload, false)
      end

      def accept
        options[:accept]
      end

      def max_file_size
        options[:max_file_size]
      end

      def self.search_config_for(_field)
        nil
      end
    end
  end
end
