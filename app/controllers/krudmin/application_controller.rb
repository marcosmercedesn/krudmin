module Krudmin
  class ApplicationController < Krudmin::Config.parent_controller.constantize
    include Krudmin::KrudminControllerSupport
    include Krudmin::KrudminResourceManagerControllerSupport
    include Krudmin::Authorizable
    include Krudmin::ModelStatusToggler
    include Krudmin::CrudMessages
    include Krudmin::Searchable
    include Krudmin::ActionButtonsSupport
    include Krudmin::BulkActions
    include Krudmin::HelperIncluder

    layout Krudmin::Config.layout

    before_action :set_view_path
    before_action :set_model, only: [:new, :edit, :create]
    helper_method :requested_editable_fields, :requested_lookup_fields, :search_term, :search_id, :request_mode_search?

    def index; end

    def edit
      model.destroy if params.fetch(:failed_destroy, false)

      respond_to do |format|
        format.html
        format.json
        format.turbo_stream if remote_modal_request?
      end
    end

    def show
      respond_to do |format|
        format.html
        format.json
        format.turbo_stream if remote_modal_request?
      end
    end

    def new
      respond_to do |format|
        format.html
        format.json
        format.turbo_stream if remote_modal_request?
      end
    end

    def create
      model.attributes = model_params

      authorize_model(model)

      Krudmin::MutationHandlers::CreateHandler.(self, model, created_message)
    end

    def update
      model.attributes = model_params

      Krudmin::MutationHandlers::UpdateHandler.(self, model, modified_message)
    end

    def destroy
      Krudmin::MutationHandlers::DestroyHandler.(self, model, destroyed_message, cant_be_destroyed_message)
    end

    def transition
      event_name = params.require(:event)

      Krudmin::MutationHandlers::TransitionHandler.(
        self,
        event_name,
        transitioned_message(event_name),
        cant_be_transitioned_message(event_name)
      )
    end

    def page
      params.fetch(:page, 0)
    end

    def limit
      params.fetch(:limit, 25)
    end

    def form_context
      params[:form_context]
    end

    def modal_form_context?
      form_context == "modal"
    end

    def inline_edit_context?
      params[:inline_edit].present?
    end

    def remote_modal_request?
      params[:remote_modal].present?
    end

    private

    def set_model
      @model = model
    end

    def authorize_model(model = nil)
      model
    end

    def set_view_path
      lookup_context.prefixes.append Krudmin::Config.theme
    end

    def requested_editable_fields
      requested_fields = Array(params[:fields]).map(&:to_sym)
      requested_fields.any? ? (editable_attributes & requested_fields) : editable_attributes
    end

    def requested_lookup_fields
      requested_fields = Array(params[:fields]).map(&:to_sym)
      available_lookup_attributes = lookup_attributes + editable_attributes
      requested_fields.any? ? (available_lookup_attributes & requested_fields) : available_lookup_attributes
    end

    def request_mode
      params[:request_mode]
    end

    def request_mode_search?
      request_mode == "search"
    end

    def search_term
      params[:search_term]
    end

    def search_id
      params[:search_id]
    end
  end
end
