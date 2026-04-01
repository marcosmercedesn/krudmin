Rails.application.routes.draw do
  root to: "docs#index"

  resources :docs

  resources :car_brands do
    collection do
      post :bulk_destroy
    end
  end

  namespace :admin do
    root to: "dashboard#show"

    get :dashboard, to: "dashboard#show"

    resources :customs, only: [:index, :show]

    resources :cars do
      member do
        post :activate
        post :deactivate
      end
      collection do
        post :bulk_destroy
        post :bulk_activate
        post :bulk_deactivate
      end
    end
  end

  # namespace :krudmin do
  #   devise_for :profile, class_name: "Krudmin::User", controllers: { sessions: "krudmin/sessions", passwords: "krudmin/passwords" }

  #   resources :users do
  #     member do
  #       post :activate
  #       post :deactivate
  #       post :send_reset_password_instructions
  #     end
  #   end
  # end
end
