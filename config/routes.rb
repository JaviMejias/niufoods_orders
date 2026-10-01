Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      resources :orders, only: %i[create index show]

      namespace :store do
        resources :restaurants, only: [] do
          resources :orders, only: [ :create ]
        end
      end
    end
  end
end
