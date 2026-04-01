module Krudmin
  module BulkActions
    extend ActiveSupport::Concern

    included do
      helper_method :bulk_actions_enabled?
    end

    def bulk_destroy
      ids = bulk_ids
      destroyed_count = 0

      scope.where(id: ids).find_each do |record|
        destroyed_count += 1 if record.destroy
      end

      respond_to do |format|
        format.html do
          flash[:error] = bulk_destroyed_message(destroyed_count)
          redirect_to resource_root, status: :see_other
        end

        format.turbo_stream do
          @bulk_ids = ids
          @bulk_message = bulk_destroyed_message(destroyed_count)
          render "bulk_destroy"
        end
      end
    end

    def bulk_activate
      ids = bulk_ids
      activated_count = 0

      scope.where(id: ids).find_each do |record|
        activated_count += 1 if record.activate!
      end

      respond_to do |format|
        format.html do
          flash[:success] = bulk_activated_message(activated_count)
          redirect_to resource_root, status: :see_other
        end

        format.turbo_stream do
          @bulk_models = scope.where(id: ids)
          @bulk_message = bulk_activated_message(activated_count)
          render "bulk_activate"
        end
      end
    end

    def bulk_deactivate
      ids = bulk_ids
      deactivated_count = 0

      scope.where(id: ids).find_each do |record|
        deactivated_count += 1 if record.deactivate!
      end

      respond_to do |format|
        format.html do
          flash[:warning] = bulk_deactivated_message(deactivated_count)
          redirect_to resource_root, status: :see_other
        end

        format.turbo_stream do
          @bulk_models = scope.where(id: ids)
          @bulk_message = bulk_deactivated_message(deactivated_count)
          render "bulk_deactivate"
        end
      end
    end

    def bulk_actions_enabled?
      krudmin_manager.bulk_actions?
    end

    private

    def bulk_ids
      Array(params[:ids]).map(&:to_i).reject(&:zero?)
    end

    def bulk_destroyed_message(count)
      I18n.t("krudmin.messages.bulk_destroyed", count: count, label: resources_label)
    end

    def bulk_activated_message(count)
      I18n.t("krudmin.messages.bulk_activated", count: count, label: resources_label)
    end

    def bulk_deactivated_message(count)
      I18n.t("krudmin.messages.bulk_deactivated", count: count, label: resources_label)
    end
  end
end
