require "rails_helper"

describe "car form transition toolbar", type: :feature do
  let(:car_model) { "Camry" }
  let(:car) { create(:car, model: car_model, status: :draft) }
  let(:car_page) { CarPage.new(url: edit_admin_car_path(car), model: car) }

  before do
    car_page.visit_page
  end

  it "transitions the model from the form toolbar" do
    expect(page).to have_link("Submit")
    expect(page).not_to have_link("Approve")
    expect(page).not_to have_link("Reject")

    click_link("Submit")

    expect(page).to have_content("#{car_model} was successfully transitioned via Submit")
    expect(car_page).to be_on_edit_page
    expect(car.reload.status).to eq("submitted")
    expect(page).not_to have_link("Submit")
    expect(page).to have_link("Approve")
    expect(page).to have_link("Reject")
  end
end
