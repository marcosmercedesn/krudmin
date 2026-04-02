module Krudmin
  module Audit
    class NullBackend < BaseBackend
      def record(payload)
        # no-op
      end

      def entries_for(record, limit: 25)
        []
      end
    end
  end
end
