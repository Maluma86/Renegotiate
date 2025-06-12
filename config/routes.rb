Rails.application.routes.draw do
  devise_for :users
  # when you log in it leads to the list products page
  root to: "products#index"

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Defines the root path route ("/")
  # root "posts#index"

  # creating the routes related to products
  resources :products, only: [:index, :show] do
    collection do
      get :import   # shows the import form
      post :upload  # uploading the CSV
    end

    resources :renegotiations, only: [:new, :create]
  end
end
