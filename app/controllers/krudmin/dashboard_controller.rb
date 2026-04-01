module Krudmin
  class DashboardController < Krudmin::CustomController
    DEFAULT_WIDGET_BACKGROUND_OPTIONS = %i[default slate ocean mint sand rose indigo charcoal].freeze

    include Pundit::Authorization

    before_action :set_view_path

    helper_method :dashboard, :widget_background_options

    def show
      dashboard.render_toolbar(view_context)

      render template: "#{Krudmin::Config.theme}/dashboard/show"
    end

    def dashboard
      @dashboard ||= dashboard_class.new(context: Krudmin::Dashboards::Context.new(self))
    end

    def pundit_user
      _current_user
    end

    def widget_background_options
      DEFAULT_WIDGET_BACKGROUND_OPTIONS
    end

    private

    def dashboard_class
      @dashboard_class ||= inferred_dashboard_class
    end

    def inferred_dashboard_class
      "#{self.class.name.deconstantize}#{self.class.name.demodulize.delete_suffix('Controller')}".constantize
    rescue NameError
      "#{self.class.name.demodulize.delete_suffix('Controller')}".constantize
    end

    def set_view_path
      lookup_context.prefixes.append Krudmin::Config.theme
    end
  end
end