Rails.application.routes.draw do
  # Engines
  mount Ivy::Engine => '/', as: :ivy_engine

  namespace :api do
    ['v1'].each do |version|
      namespace version do
        namespace :irv do
          resources :nonrack_devices do
            get :modified, :on => :collection
          end
        end
        namespace :groups do
          resources :groups, only: [:index]
        end
      end
    end
  end
end
