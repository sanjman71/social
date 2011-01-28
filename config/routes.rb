Social::Application.routes.draw do

  root :to => "home#index"

  # devise
  devise_for :users, :controllers => {:omniauth_callbacks => "oauth" }
  devise_scope :user do
    get "/login" => "devise/sessions#new", :as => :new_user_session
    get "/logout" => "devise/sessions#destroy", :as => :logout
    get "/signup" => "devise/registrations#new", :as => :signup
  end

  # checkin routes
  match 'users/:user_id/:checkins/:geo/:radius(/:search)', :to => 'checkins#search',
    :constraints => {:checkins => /checkins|todos/, :geo => /geo:\d+\.\d+\.\.-{0,1}\d+\.\d+/,
                     :radius => /radius:\d+/},
    :as => :geo_checkins
  match 'users/:user_id/:checkins/:city/:radius(/:search)', :to => 'checkins#search',
    :constraints => {:checkins => /checkins|todos/, :city => /city:[a-z-]+/, :radius => /radius:\d+/},
    :as => :city_checkins
  match 'users/:user_id/:checkins(/:search)', :to => "checkins#search",
    :constraints => {:checkins => /checkins|todos/}, :as => :checkins
  match 'checkins', :to => 'checkins#index'

  match 'sightings', :to => "sightings#index"
  match 'accounts', :to => "accounts#index"
  match 'accounts/:service/unlink', :to => "accounts#unlink", :as => :unlink_account, :via => [:delete]
  match 'growls', :to => "growls#index"

  # user routes
  match 'users/:geo(/:radius)', :to => 'users#index',
    :constraints => {:geo => /geo:\d+\.\d+\.\.-{0,1}\d+\.\d+/, :radius => /radius:\d+/}, :as => :geo_users
  match 'users/:city(/:radius)', :to => 'users#index',
    :constraints => {:city => /city:[a-z-]+/, :radius => /radius:\d+/}, :as => :city_users
  match 'users/:id/bucks/:points', :to => "users#bucks", :as => :add_bucks_user
  match 'users/:id/via/:source', :to => "users#via", :as => :user_via

  match 'profile', :to => 'users#show', :via => :get
  match 'settings', :to => 'settings#show', :via => :get
  match 'settings', :to => 'settings#update', :via => :put

  resources :users do
    get :become, :on => :member
  end

  # location routes
  match 'locations/:geo(/:radius)', :to => 'locations#index',
    :constraints => {:geo => /geo:\d+\.\d+\.\.-{0,1}\d+\.\d+/, :radius => /radius:\d+/}, :as => :geo_locations
  match 'locations/:city(/:radius)', :to => 'locations#index',
    :constraints => {:city => /city:[a-z-]+/, :radius => /radius:\d+/}, :as => :city_locations
  match 'locations/search/:provider', :to => 'locations#search', :as => :search_locations

  resources :locations, :only => [:index, :edit] do
    get :import_tags, :on => :member
    get :tag, :on => :member
    put :tag, :on => :member
  end

  # plans
  match 'plans/add(/:location_id)', :to => 'plans#add', :via => [:put], :as => :add_todo_location
  match 'plans/join(/:plan_id)', :to => 'plans#join', :via => [:put], :as => :join_todo
  match 'plans/remove/:location_id', :to => 'plans#remove', :via => [:put], :as => :remove_todo_location
  match 'plans', :to => 'plans#index', :via => [:get]

  # shouts
  resources :shouts, :only => [:index]
  match 'shouts/add(/:location_id)', :to => 'shouts#add', :via => [:put], :as => :add_shout

  # suggestion routes
  match 'suggestions/:id/relocate(/:location_id)', :to => 'suggestions#relocate',
    :as => :relocate_suggestion, :via => [:post, :put]
  match 'suggestions/filter::ids', :to => 'suggestions#index', :as => :filter_suggestions, :via => [:get]
  resources :suggestions, :only => [:index, :show] do
    put :add, :on => :collection
    put :decline, :on => :member
    put :confirm, :on => :member
    post :schedule, :on => :member
    put :schedule, :on => :member
    post :reschedule, :on => :member
    put :reschedule, :on => :member
  end

  # friends routes
  resources :friends, :only => [:index]
  
  # messages routes
  resources :messages, :only => [:create]

  # voting routes
  match 'vote/users/:user_id/badge/:badge_id/:vote', :to => 'voting#create', :via => [:put],
    :as => :vote_user_badge

  match 'about', :to => 'home#about', :as => :about

  # unauthorized
  match 'unauthorized', :to => 'home#unauthorized'

  match 'ping', :to => "home#ping", :via => [:get]
  match 'beta', :to => "beta#show", :via => [:get, :post]
  match 'stream/:name', :to => "home#stream", :via => [:put], :as => :home_stream
  match 'city/:name', :to => "home#city", :via => [:put], :as => :home_city

  match 'realtime', :to => "realtime#index"

  # admin routes
  scope 'admin' do
    match '', :to => 'admin#index', :as => :admin
    match 'checkins_chart', :to => 'admin#checkins_chart', :as => :admin_checkins_chart
    match 'invites_chart', :to => 'admin#invites_chart', :as => :admin_invites_chart
    match 'tags_chart', :to => 'admin#tags_chart', :as => :admin_tags_chart
    match 'users_chart', :to => 'admin#users_chart', :as => :admin_users_chart
    match 'badges', :to => 'badges#index', :as => :admin_badges
    match 'checkins', :to => 'checkins#index', :as => :admin_checkins
  end

  # pages routes
  resources :pages, :controller => 'pages', :only => :show

  # invitations
  match 'invite', :to => "invitations#new", :as => :invite, :via => [:get]
  match 'invite', :to => "invitations#create", :via => [:post]
  match 'invitees/search', :to => "invitations#search", :as => :invitee_search, :via => [:get]
  match 'invite/poke', :to => "invitations#poke", :as => :invite_poke, :via => [:put]

  # badges
  resources :badges do
    get :tag_search, :on => :collection
    put :add_tags, :on => :member
    put :remove_tags, :on => :member
  end

  # jobs routes
  match 'jobs', :to => 'jobs#index', :as => :jobs
  match 'jobs/backup', :to => 'jobs#backup', :as => :backup_job
  match 'jobs/sphinx', :to => 'jobs#sphinx', :as => :sphinx_job
  match 'jobs/top', :to => 'jobs#top', :as => :top_job

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
