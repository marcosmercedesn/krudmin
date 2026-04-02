require_relative "audit/base_backend"
require_relative "audit/null_backend"
require_relative "audit/krudmin_backend"
require_relative "audit/paper_trail_backend"
require_relative "audit/custom_backend"

module Krudmin
  module Audit
    module_function

    def record(event:, record:, user: nil, changes: nil, metadata: {})
      return unless Krudmin::Config.audit_enabled?

      payload = {
        auditable_type: record.class.name,
        auditable_id: record.id,
        user_type: user&.class&.name,
        user_id: user.respond_to?(:id) ? user.id : nil,
        action: event.to_s,
        changes: changes || extract_changes(record),
        metadata: metadata
      }

      Krudmin::Config.audit_backend_instance.record(payload)
      payload
    rescue StandardError => e
      Rails.logger.warn("[Krudmin::Audit] Failed to record: #{e.message}") if defined?(Rails)
      nil
    end

    def entries_for(record, limit: 25)
      return [] unless Krudmin::Config.audit_enabled?

      Krudmin::Config.audit_backend_instance.entries_for(record, limit: limit)
    rescue StandardError
      []
    end

    def extract_changes(record)
      return {} unless record.respond_to?(:previous_changes)

      excluded = Krudmin::Config.audit_excluded_attributes
      record.previous_changes.reject { |k, _| excluded.include?(k.to_sym) }
    end
  end
end
