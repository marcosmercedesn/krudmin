require "rails_helper"

RSpec.describe "Admin::Cars state machine transitions", type: :request do
  let!(:car) { create(:car, status: :draft) }

  it "transitions successfully with a valid AASM event" do
    post transition_admin_car_path(car), params: { event: "submit", context: "list" }

    expect(response).to have_http_status(:see_other).or have_http_status(:ok)
    expect(car.reload.status).to eq("submitted")
  end

  it "does not transition with an invalid AASM event" do
    post transition_admin_car_path(car), params: { event: "pay", context: "list" }

    expect(response).to have_http_status(:see_other).or have_http_status(:ok)
    expect(car.reload.status).to eq("draft")
  end
end
