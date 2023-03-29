Rails.application.routes.draw do
  # Engines
  mount Ivy::Engine  => '/', as: :ivy_engine
  mount Meca::Engine => '/', as: :meca_engine
  mount Uma::Engine  => '/', as: :uma_engine

  # We need to redirect here, otherwise the devise redirections will take us to
  # the legacy sign up page.
  root to: redirect('/irv')

  # API routes
  #
  # Some of these have been done in a non-railsy way (you have "posts" where you should have 
  # "puts", missing plurals where we should have plurals... to be tidied up at some point.
  #
  namespace :api do
    ['v1'].each do |version|
      namespace version do

        resources :racks
        resources :templates, only: [:index]
        resources :nodes, only: [:create]
        resources :devices, only: [:index, :show, :update, :destroy]

        namespace :irv do
          resources :racks, only: [:index] do
            member do
              get :tooltip
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
            end
          end
          resources :rackview_presets, only: [:index, :create, :update, :destroy]
          resources :metrics, :constraints => { :id => /.*/ }, only: [] do
            member do
              post :show
            end
          end
        end

        namespace :metrics do
          resources :metrics, :constraints => { :id => /.*/ }, only: [] do
            get :structure, :on => :collection
          end
        end

        namespace :users do
          resources :users, only: [] do
            collection do
              # Endpoint for checking user abilities.
              get :can_i, action: :can_i?, as: :ability_check
            end
          end
        end
      end
    end
  end
end
