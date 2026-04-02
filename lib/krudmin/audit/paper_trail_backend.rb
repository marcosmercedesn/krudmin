module Krudmin
  module Audit
    class PaperTrailBackend < BaseBackend
      def record(payload)
        # PaperTrail records automatically via model callbacks.
        # This backend is used only for querying.
        # If you need manual recording, use PaperTrail::RecordTrail directly.
      end

      def entries_for(record, limit: 25)
        return [] unless record.respond_to?(:versions)

        record.versions.order(created_at: :desc).limit(limit).map do |version|
          OpenStruct.new(
            action: version.event,
            changes_json: (version.changeset || {}).to_json,
            user_id: version.whodunnit,
            user_type: nil,
            created_at: version.created_at,
            metadata: {}.to_json
          )
        end
      end
    end
  end
end
