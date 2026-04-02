module Krudmin
  module Audit
    class KrudminBackend < BaseBackend
      def record(payload)
        Krudmin::AuditEntry.create!(
          auditable_type: payload[:auditable_type],
          auditable_id: payload[:auditable_id],
          user_type: payload[:user_type],
          user_id: payload[:user_id],
          action: payload[:action],
          changes_json: (payload[:changes] || {}).to_json,
          metadata: (payload[:metadata] || {}).to_json,
          created_at: Time.current
        )
      end

      def entries_for(record, limit: 25)
        Krudmin::AuditEntry
          .where(auditable_type: record.class.name, auditable_id: record.id)
          .order(created_at: :desc)
          .limit(limit)
      end
    end
  end
end
