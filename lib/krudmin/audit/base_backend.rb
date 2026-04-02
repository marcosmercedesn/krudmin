module Krudmin
  module Audit
    class BaseBackend
      def record(payload)
        raise NotImplementedError, "#{self.class}#record must be implemented"
      end

      def entries_for(record, limit: 25)
        raise NotImplementedError, "#{self.class}#entries_for must be implemented"
      end
    end
  end
end
