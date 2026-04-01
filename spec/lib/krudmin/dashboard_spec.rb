require "rails_helper"

describe Krudmin::Dashboard do
  class DashboardSpecDashboard < Krudmin::Dashboard
    page_title "Spec Dashboard"

    widget :count,
           resource: CarsResourceManager,
           scope: :active,
           label: "Active Cars",
           background: :mint
  end

  let!(:car_brand) { create(:car_brand) }
  let!(:active_car) { create(:car, active: true, car_brand: car_brand) }
  let!(:inactive_car) { create(:car, active: false, car_brand: car_brand) }

  let(:controller) do
    double(
      _current_user: nil,
      policy_scope: Car.all,
      policy: double(index?: true),
      view_context: double,
      widget_background_options: %i[default mint]
    )
  end

  let(:context) { Krudmin::Dashboards::Context.new(controller) }

  it "builds widgets from ResourceManagers and applies dashboard scopes" do
    dashboard = DashboardSpecDashboard.new(context: context)

    expect(dashboard.page_title).to eq("Spec Dashboard")
    expect(dashboard.widgets.length).to eq(1)
    expect(dashboard.widgets.first).to be_a(Krudmin::Dashboards::Widgets::CountWidget)
    expect(dashboard.widgets.first.value).to eq(1)
    expect(dashboard.widgets.first.background).to eq(:mint)
    expect(dashboard.widgets.first.background_class).to eq("dashboard-widget-bg-mint")
  end

  it "falls back to default when widget background is not enabled by controller" do
    dashboard_class = Class.new(Krudmin::Dashboard) do
      widget :count,
             resource: CarsResourceManager,
             label: "Cars",
             background: :charcoal
    end

    dashboard = dashboard_class.new(context: context)

    expect(dashboard.widgets.first.background).to eq(:default)
  end
end