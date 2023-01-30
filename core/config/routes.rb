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
          resources :racks
          resources :nonrack_devices
        end

        namespace :groups do
          resources :groups, only: [:index]
        end

        namespace :metrics do
          resources :metrics, :constraints => { :id => /.*/ }, only: [] do
            # get :index, :on => :collection
            get :structure, :on => :collection
          end
        end
      end
    end
  end
end
