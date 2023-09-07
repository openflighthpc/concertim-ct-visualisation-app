Rails.application.routes.draw do
  # Engines
  mount Ivy::Engine  => '/', as: :ivy_engine
  mount Meca::Engine => '/', as: :meca_engine
  authenticate :user, ->(user) { user.root? } do
    mount GoodJob::Engine => 'good_job'
  end

  scope module: :uma do
    devise_for :users, class_name: "Uma::User", only: [:sessions, :registrations]
  end

  # We need to redirect here, otherwise the devise redirections will take us to
  # the legacy sign up page.
  root to: redirect('/irv')

  namespace :fleece, path: 'cloud-env' do
    resource :config do
      member do
        post :send_config, as: 'send', path: 'send'
      end
    end
    resources :cluster_types, path: 'cluster-types', only: [:index], param: :foreign_id do
      resources :clusters, only: [:new, :create]
    end
  end

  scope module: :fleece do
    resources :users, only: [] do
      collection do
        resources :key_pairs, only: [:index, :new, :create] do
          collection do
            get '/success', to: 'key_pairs#success'
            delete '/:name', to: 'key_pairs#destroy', as: :delete
          end
        end
      end
    end
  end

  # API routes
  #
  # Some of these have been done in a non-railsy way (you have "posts" where you should have 
  # "puts", missing plurals where we should have plurals... to be tidied up at some point.
  #
  namespace :api do
    ['v1'].each do |version|
      namespace version do

        resources :racks
        resources :templates, only: [:index, :create, :update, :destroy]
        resources :nodes, only: [:create]
        resources :devices, only: [:index, :show, :update, :destroy]

        namespace :irv do
          resources :racks, only: [:index] do
            member do
              get :tooltip
              post :request_status_change
            end
            collection do 
              get :modified
            end
          end
          resources :nonrack_devices, only: [:index] do
            collection do
              get :modified
            end
          end
          resources :chassis do
            member do
              get :tooltip
              post :update_position
            end
          end
          resources :devices, only: [] do
            member do
              get :tooltip
              post :update_slot
              post :request_status_change
            end
          end
          resources :rackview_presets, only: [:index, :create, :update, :destroy]
          resources :metrics, :constraints => { :id => /.*/ }, only: [] do
            member do
              post :show
            end
          end
        end

        resources :groups, only: [:index, :show]
        resources :metrics, :constraints => { :id => /.*/ }, only: [] do
          get :structure, :on => :collection
        end
        resources :users, only: [:index, :update] do
          collection do
            # Endpoint for checking user abilities.
            get :can_i, action: :can_i?, as: :ability_check
            # Endpoint for getting the currently signed in user.
            get :current
          end
        end
      end
    end
  end
end
