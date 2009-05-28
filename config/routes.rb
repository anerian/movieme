ActionController::Routing::Routes.draw do |map|
  map.resources :theaters
  map.resource :user_session
  
  map.namespace :admin do |admin|
    admin.resources :theaters
  end
end
