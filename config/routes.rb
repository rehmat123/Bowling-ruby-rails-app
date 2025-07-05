Rails.application.routes.draw do
  resources :games, only: [:create, :show] do
    member do
      get :score
    end
    resources :rolls, only: [:create]
  end

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  get "up" => "rails/health#show", as: :rails_health_check
end
