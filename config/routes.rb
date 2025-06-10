Rails.application.routes.draw do
  devise_for :users
  # when you log in it leads to the list products page
  root to: "products#index"

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # CRUD Renegotiation workflow with AI-powered target confirmation
  resources :renegotiations do
    member do
      get :confirm_target # GET /renegotiations/:id/confirm_target
      post :set_target # POST /renegotiations/:id/set_target
    end
  end

  # Defines the root path route ("/")
  # root "posts#index"

  # creating the routes related to products
  resources :products, only: [:index]
end
