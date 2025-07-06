Rails.application.routes.draw do
  # API namespace with versioning in URL but non-versioned controllers
  namespace :api do
    scope :v1 do
      resources :games, only: [ :create, :show ], defaults: { format: :json } do
        member do
          get :score
        end
        resources :rolls, only: [ :create ], defaults: { format: :json }
      end
    end
  end

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  get "up" => "rails/health#show", as: :rails_health_check
end
