Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      resources :orders, only: %i[create index]

      namespace :store do
        resources :orders, only: [:create]
      end
    end
  end
end