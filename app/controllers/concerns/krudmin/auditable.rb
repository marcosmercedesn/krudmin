module Krudmin
  module Auditable
    extend ActiveSupport::Concern

    included do
      if Krudmin::Config.audit_enabled?
        around_action :capture_audit_changes, only: [:create, :update, :destroy, :activate, :deactivate, :transition]
        helper_method :audit_entries_for, :audit_enabled?
      end
    end

    def audit_enabled?
      Krudmin::Config.audit_enabled?
    end

    def audit_entries_for(record, limit: 25)
      Krudmin::Config.audit_backend_instance.entries_for(record, limit: limit)
    end

    private

    def capture_audit_changes
      @_audit_changes_before = model.changes.dup if model.respond_to?(:changes)
      @_audit_attributes_snapshot = model.attributes.dup if action_name == "destroy"

      yield

      record_audit_entry
    rescue => e
      raise e
    end

    def record_audit_entry
      return unless model.respond_to?(:id)

      audit_action = determine_audit_action
      changes = determine_audit_changes(audit_action)

      return if audit_action == "update" && changes.empty?

      payload = {
        auditable_type: model.class.name,
        auditable_id: model.id,
        user_type: audit_user&.class&.name,
        user_id: audit_user_id,
        action: audit_action,
        changes: changes,
        metadata: audit_metadata
      }

      Krudmin::Config.audit_backend_instance.record(payload)
    rescue => e
      Rails.logger.warn("[Krudmin::Audit] Failed to record audit entry: #{e.message}")
    end

    def determine_audit_action
      case action_name
      when "create" then "create"
      when "update" then "update"
      when "destroy" then "destroy"
      when "activate" then "activate"
      when "deactivate" then "deactivate"
      when "transition" then "transition"
      else action_name
      end
    end

    def determine_audit_changes(audit_action)
      excluded = audit_excluded_attributes

      case audit_action
      when "create"
        model.respond_to?(:previous_changes) ? filter_changes(model.previous_changes, excluded) : {}
      when "update"
        model.respond_to?(:previous_changes) ? filter_changes(model.previous_changes, excluded) : {}
      when "destroy"
        @_audit_attributes_snapshot&.reject { |k, _| excluded.include?(k.to_sym) } || {}
      when "activate", "deactivate"
        model.respond_to?(:previous_changes) ? filter_changes(model.previous_changes, excluded) : {}
      when "transition"
        model.respond_to?(:previous_changes) ? filter_changes(model.previous_changes, excluded) : {}
      else
        {}
      end
    end

    def filter_changes(changes, excluded)
      changes.reject { |k, _| excluded.include?(k.to_sym) }
    end

    def audit_excluded_attributes
      global = Krudmin::Config.audit_excluded_attributes
      per_resource = if krudmin_manager.class.const_defined?(:AUDIT_EXCLUDED_ATTRIBUTES)
                       krudmin_manager.class::AUDIT_EXCLUDED_ATTRIBUTES
                     else
                       []
                     end
      (global + per_resource).map(&:to_sym).uniq
    end

    def audit_user
      _current_user
    rescue
      nil
    end

    def audit_user_id
      audit_user&.respond_to?(:id) ? audit_user.id : nil
    end

    def audit_metadata
      meta = {
        controller: controller_path,
        action: action_name,
        ip: request.remote_ip
      }

      meta[:event] = params[:event] if action_name == "transition"

      meta
    end
  end
end
