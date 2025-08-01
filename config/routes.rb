Rails.application.routes.draw do
  namespace :admin do
    resources :users, only: [:index, :show, :edit, :update]
  end
  # Authentication routes
  get "/signup", to: "users#new"
  post "/signup", to: "users#create"
  get "/signin", to: "sessions#new"
  post "/signin", to: "sessions#create"
  delete "/signout", to: "sessions#destroy"

  resources :blog_sites do
    member do
      post :retry_discovery
      get :discovered_urls
      delete :clear_discovered_urls
      delete 'delete_discovered_url/:article_id', to: 'blog_sites#delete_discovered_url', as: :delete_discovered_url
    end
    resources :articles do
      member do
        post :generate_summary
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

  # Defines the root path route ("/")
  root "blog_sites#index"
end
