Rails.application.routes.draw do
  root "runs#index"

  resources :users, only: [ :new, :create, :show, :update ]
  resources :runs, only: [ :new, :create, :index, :edit, :update, :destroy ]
  get "bronco_tutorials", to: "runs#bronco_tutorials", as: "bronco_tutorials"
  resources :plays, only: [ :index, :new, :create, :show ]

  # Voting routes
  post "/runs/vote", to: "runs#create_vote", as: :run_vote

  get    "/login",  to: "sessions#new"
  post   "/login",  to: "sessions#create"
  delete "/logout", to: "sessions#destroy"

  # Password setup for new users
  get    "/setup-password", to: "sessions#setup_password", as: :setup_password
  post   "/setup-password", to: "sessions#create_password"

  # User profiles
  get "/profile", to: "users#profile"

  # Admin routes
  namespace :admin do
    get "dashboard", to: "dashboard#index"
    post "dashboard/sync", to: "dashboard#trigger_strava_sync", as: :dashboard_sync
    post "dashboard/backdate-sync", to: "dashboard#trigger_backdate_strava_sync", as: :dashboard_backdate_sync

    resources :runs, only: [ :index, :edit, :update, :destroy ]
    resources :users, only: [ :index, :destroy ] do
      member do
        patch :promote_admin
        patch :demote_admin
        patch :update_user_type
      end
    end
    resources :race_deadlines
    resources :plays, only: [ :index, :show, :destroy ] do
      member do
        patch :approve
        patch :reject
      end
    end
  end

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
end
