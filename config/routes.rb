Rails.application.routes.draw do
  resources :publications

  namespace :api, defaults: { format: :json } do
    get 'statistics/publications_count', to: 'statistics#publications_count'
    get 'statistics/conferences_count', to: 'statistics#conferences_count'
    get 'statistics/publications_by_research_groups_count', to: 'statistics#publications_by_research_groups_count'
    get 'statistics/publications_by_category_count', to: 'statistics#publications_by_category_count'
    get 'statistics/publications_by_status_count', to: 'statistics#publications_by_status_count'
    get 'statistics/average_impact_factor', to: 'statistics#average_impact_factor'
  end
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  root "publications#index"
end
