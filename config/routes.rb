Rails.application.routes.draw do
  devise_for :users
  # when you log in it leads to the list products page
  root to: "products#index"

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Insights page
  get "insights", to: "pages#insights"

  # CRUD Renegotiation workflow with AI-powered target confirmation
  resources :renegotiations do
    member do
      get :confirm_target          # GET /renegotiations/:id/confirm_target
      post :set_target             # POST /renegotiations/:id/set_target
      post :save_discount_targets  # POST /renegotiations/:id/save_discount_targets
      post :start_product_intelligence    # POST /renegotiations/:id/start_product_intelligence
      get :product_intelligence_status    # GET /renegotiations/:id/product_intelligence_status
    end
    resources :questions, only: [:index, :create] # LS changed, a question belongs to a renegotiation
  end

  # Defines the root path route ("/")
  # root "posts#index"

  # Below for the chatbot

  # creating the routes related to products
  # Products routes
  resources :products, only: [:index, :show] do
    collection do
      get :import   # shows the import form
      post :upload  # uploading the CSV
    end

    resources :renegotiations, only: [:new, :create]
  end
end
