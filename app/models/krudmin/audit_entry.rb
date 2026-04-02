module Krudmin
  class AuditEntry < ActiveRecord::Base
    self.table_name = "krudmin_audit_entries"

    belongs_to :auditable, polymorphic: true, optional: true
    belongs_to :user, polymorphic: true, optional: true

    scope :recent, -> { order(created_at: :desc) }
    scope :for_record, ->(record) { where(auditable_type: record.class.name, auditable_id: record.id) }

    def parsed_changes
      JSON.parse(changes_json || "{}")
    rescue JSON::ParserError
      {}
    end

    def parsed_metadata
      JSON.parse(metadata || "{}")
    rescue JSON::ParserError
      {}
    end

    def user_label
      return "System" unless user

      if user.respond_to?(:name)
        user.name
      elsif user.respond_to?(:email)
        user.email
      else
        "User ##{user_id}"
      end
    end

    def action_label
      I18n.t("krudmin.audit.actions.#{action}", default: action.to_s.humanize)
    end
  end
end
