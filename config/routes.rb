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

  match 'users/:user_id/checkins', :to => "checkins#index", :as => :user_checkins
  match 'checkins', :to => "checkins#index"
  match 'checkins/:source/:source_id/count', :to => 'checkins#count', :as => :count_checkins
  match 'checkins/poll', :to => "checkins#poll", :as => :poll_checkins
  match 'sightings', :to => "sightings#index"
  match 'accounts', :to => "accounts#index"
  match 'accounts/:service/unlink', :to => "accounts#unlink", :as => :unlink_account, :via => [:delete]
  match 'growls', :to => "growls#index"

  # user routes

  match 'users/:geo(/:radius)', :to => 'users#index',
    :constraints => {:geo => /geo:\d+\.\d+\.\.-{0,1}\d+\.\d+/, :radius => /radius:\d+/}, :as => :geo_users
  match 'users/:city(/:radius)', :to => 'users#index',
    :constraints => {:city => /city:[a-z-]+/, :radius => /radius:\d+/}, :as => :city_users

  resources :users

  # location routes
  match 'locations/:geo(/:radius)', :to => 'locations#index',
    :constraints => {:geo => /geo:\d+\.\d+\.\.-{0,1}\d+\.\d+/, :radius => /radius:\d+/}, :as => :geo_locations
  match 'locations/:city(/:radius)', :to => 'locations#index',
    :constraints => {:city => /city:[a-z-]+/, :radius => /radius:\d+/}, :as => :city_locations

  resources :locations, :only => [:index] do
    get :import_tags, :on => :member
  end

  resources :suggestions, :only => [:index, :show] do
    put :decline, :on => :member
    put :confirm, :on => :member
    post :schedule, :on => :member
    put :schedule, :on => :member
    post :reschedule, :on => :member
    put :reschedule, :on => :member
  end

  # friends routes
  resources :friends, :only => [:index]
  
  # plans routes
  match 'plans/add/:location_id', :to => 'plans#add', :via => [:put], :as => :add_planned_location
  match 'plans/remove/:location_id', :to => 'plans#remove', :via => [:put], :as => :remove_planned_location
  
  # voting routes
  match 'vote/users/:user_id/badge/:badge_id/:vote', :to => 'voting#create', :via => [:put],
    :as => :vote_user_tag_badge
  match 'jobs', :to => 'jobs#index', :as => :jobs
  match 'jobs/backup', :to => 'jobs#backup', :as => :backup_job
  match 'jobs/sphinx', :to => 'jobs#sphinx', :as => :sphinx_job

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
