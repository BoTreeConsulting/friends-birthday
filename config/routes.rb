FriendsBirthday::Application.routes.draw do
  get "festival_avatars/index"

  get "festival_avatars/new"

  resources :restricted_friends

  get "birthday_avatars/index"

  get "birthday_avatars/new"
  get "festival_avatars/new"

  get "birthday_avatars/edit"
  match "/birthday_avatars/create" => "birthday_avatars#create"
  match "/festival_avatars/create" => "festival_avatars#create"
  resources :custom_messages

  devise_for :users , :controllers => { :omniauth_callbacks => "users/omniauth_callbacks" } do
    match '/users/sign_out' => 'devise/sessions#destroy'
    match '/users/sign_in' => 'users/sessions#create'
  end

  get "home/index"
  match '/analysis/:provider' => 'home#analysis'
  match 'destroy_fb_authentication' => 'home#destroy_fb_authentication'
  match '/restricted_friends'  => "restricted_friends#index"
  get '/m_get_friends_birthday'  => "home#m_get_friends_birthday",:format => "json"
  # The priority is based upon order of creation:
  # first created -> highest priority.

  # Sample of regular route:
  #   match 'products/:id' => 'catalog#view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  #   match 'products/:id/purchase' => 'catalog#purchase', :as => :purchase
  # This route can be invoked with purchase_url(:id => product.id)

  # Sample resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Sample resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Sample resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Sample resource route with more complex sub-resources
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', :on => :collection
  #     end
  #   end

  # Sample resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end

  # You can have the root of your site routed with "root"
  # just remember to delete public/index.html.
   root :to => 'home#index'

  # See how all your routes lay out with "rake routes"

  # This is a legacy wild controller route that's not recommended for RESTful applications.
  # Note: This route will make all actions in every controller accessible via GET requests.
  # match ':controller(/:action(/:id))(.:format)'
end
