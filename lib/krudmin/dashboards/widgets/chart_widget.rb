module Krudmin
  module Dashboards
    module Widgets
      class ChartWidget < Base
        DEFAULT_GRID_CLASS = "col-12 col-xl-6"

        def series
          @series ||= grouped_values.map do |label, value|
            {
              label: label.presence || I18n.t("krudmin.labels.no_data"),
              value: value,
              percentage: total.positive? ? ((value.to_f / total) * 100).round(1) : 0
            }
          end
        end

        def total
          @total ||= grouped_values.values.sum
        end

        def empty?
          total.zero?
        end

        private

        def grouped_values
          relation.to_a.group_by { |record| group_value_for(record) }.transform_values(&:count).sort_by { |(_label, value)| -value }.to_h
        end

        def group_value_for(record)
          value = record.public_send(group_by)

          return format_period(value) if period.present?
          return I18n.t("krudmin.labels.yes") if value == true
          return I18n.t("krudmin.labels.no") if value == false

          value.to_s.humanize
        end

        def format_period(value)
          return I18n.t("krudmin.labels.no_data") unless value.respond_to?(:to_date)

          case period.to_sym
          when :day
            value.to_date.strftime("%b %d")
          when :month
            value.to_date.strftime("%b %Y")
          when :year
            value.to_date.strftime("%Y")
          else
            value.to_date.to_s
          end
        end

        def group_by
          options.fetch(:group_by).to_sym
        end

        def period
          options[:period]
        end
      end
    end
  end
end