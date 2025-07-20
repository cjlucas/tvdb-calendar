Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Root route - homepage with PIN input
  root "home#index"
  
  # User management
  post "users", to: "users#create"
  
  # ICS calendar download
  get "calendar/:user_id", to: "calendar#show", as: :user_calendar
  
  # ActionCable WebSocket endpoint
  mount ActionCable.server => '/cable'
end
