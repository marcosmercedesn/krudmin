require "rails_helper"

describe Admin::DashboardController, type: :controller do
  render_views

  let!(:car_brand) { create(:car_brand, description: "Toyota") }
  let!(:active_car) { create(:car, model: "Corolla", active: true, transmission: :automatic, car_brand: car_brand, created_at: Time.zone.parse("2026-01-10")) }
  let!(:inactive_car) { create(:car, model: "Supra", active: false, transmission: :manual, car_brand: car_brand, created_at: Time.zone.parse("2026-02-15")) }

  before do
    create(:car_brand, description: "Honda")
  end

  describe "GET show" do
    it "renders the shipped demo dashboard" do
      get :show

      expect(response).to be_successful
      expect(response.body).to include("Operations Dashboard")
      expect(response.body).to include("Total Cars")
      expect(response.body).to include("Transmission Mix")
      expect(response.body).to include("Recent Cars")
      expect(response.body).to include("Corolla")
    end
  end

  describe "widget background options" do
    it "exposes a default list of enabled widget backgrounds" do
      expect(controller.widget_background_options).to include(:default, :mint, :charcoal)
    end
  end
end