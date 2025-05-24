Rails.application.routes.draw do
  root "runs#index"

  resources :users, only: [:new, :create, :show]
  resources :runs, only: [:new, :create, :index, :edit, :update, :destroy]

  get    "/login",  to: "sessions#new"
  post   "/login",  to: "sessions#create"
  delete "/logout", to: "sessions#destroy"

  # User profiles
  get "/profile", to: "users#profile"

  # Admin routes
  namespace :admin do
    resources :runs, only: [:index, :destroy]
    resources :users, only: [:index]
    resources :race_deadlines
  end

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
end
