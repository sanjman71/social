Social::Application.routes.draw do
  root :to => "home#index"

  # devise
  devise_for :users
  devise_scope :user do
    get "/login" => "devise/sessions#new"
    get "/logout" => "devise/sessions#destroy"
    get "/signup" => "devise/registrations#new"
  end

  # oauth routes
  match 'oauth/:service/initiate', :to => "oauth#initiate", :as => :oauth_initiate
  match 'oauth/:service/callback', :to => "oauth#callback", :as => :oauth_callback

  match 'checkins', :to => "checkins#index"
  match '/users/:user_id/checkins', :to => "checkins#index", :as => :user_checkins
  match 'checkins/poll', :to => "checkins#poll", :as => :poll_checkins
  match 'sightings', :to => "sightings#index"
  match 'locations', :to => "locations#index"
  match 'accounts', :to => "accounts#index"
  match 'accounts/:service/unlink', :to => "accounts#unlink", :as => :unlink_account, :via => [:delete]
  match 'users', :to => "users#index"

  resources :suggestions, :only => [:index, :show] do
    put :decline, :on => :member
    put :confirm, :on => :member
    post :schedule, :on => :member
    post :reschedule, :on => :member
  end

  match 'ping', :to => "home#ping", :via => [:get]
  match 'beta', :to => "home#beta", :via => [:get, :post]

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
  #       get :short
  #       post :toggle
  #     end
  #
  #     collection do
  #       get :sold
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
  #       get :recent, :on => :collection
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
  # root :to => "welcome#index"

  # See how all your routes lay out with "rake routes"

  # This is a legacy wild controller route that's not recommended for RESTful applications.
  # Note: This route will make all actions in every controller accessible via GET requests.
  # match ':controller(/:action(/:id(.:format)))'
end
