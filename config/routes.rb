Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # API routes
  namespace :api do
    namespace :v1 do
      get 'status', to: 'status#show'
      get 'locations/:barcode', to: 'locations#show'
      get 'items/:barcode', to: 'items#show'
      post 'add-item', to: 'inventory#add_item'
      post 'remove-item', to: 'inventory#remove_item'
    end
  end

  # Web interface routes
  root 'inventory#index'
  resources :categories do
    collection do
      get :search
    end
  end
  resources :locations, only: [:index, :show, :new, :create], param: :barcode do
    collection do
      post :print_barcodes
      get :search
    end
  end
  resources :items, only: [:index, :show, :new, :create, :edit, :update], param: :barcode do
    collection do
      post :print_barcodes
      get :search
    end
  end
  get 'inventory', to: 'inventory#index'
  get 'inventory/search', to: 'inventory#search'

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
end
