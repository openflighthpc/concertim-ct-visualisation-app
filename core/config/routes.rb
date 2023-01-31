Rails.application.routes.draw do
  # Engines
  mount Ivy::Engine  => '/', as: :ivy_engine
  mount Meca::Engine => '/', as: :meca_engine

  # API routes
  #
  # Some of these have been done in a non-railsy way (you have "posts" where you should have 
  # "puts", missing plurals where we should have plurals... to be tidied up at some point.
  #
  namespace :api do
    ['v1'].each do |version|
      namespace version do

        namespace :irv do
          resources :racks, only: [:index] do
            collection do 
              get :modified
            end
          end
          resources :thresholds, :constraints => { :id => /.*/ }, only: [:index]
          resources :nonrack_devices, only: [:index] do
            collection do
              get :modified
            end
          end
          resources :metrics, :constraints => { :id => /.*/ }, only: [] do
            member do
              post :show
            end
          end
        end

        namespace :groups do
          resources :groups, only: [:index]
        end

        namespace :metrics do
          resources :metrics, :constraints => { :id => /.*/ }, only: [] do
            get :structure, :on => :collection
          end
          resources :breaches
        end
      end
    end
  end
end
