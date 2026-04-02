module Krudmin
  module Audit
    class CustomBackend < BaseBackend
      def record(payload)
        Krudmin::Config.audit_recorder.call(payload)
      end

      def entries_for(record, limit: 25)
        Krudmin::Config.audit_entries_provider.call(record, limit: limit)
      end
    end
  end
end
