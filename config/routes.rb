ActionController::Routing::Routes.draw do |map|
  map.resources :theaters
  map.resources :movies
  map.resource :user_session
  
  map.namespace :admin do |admin|
    admin.resources :theaters
    admin.resources :movies
  end
end
