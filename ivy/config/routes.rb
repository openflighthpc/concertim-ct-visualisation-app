Ivy::Engine.routes.draw do
  resource :irv, only: :show do
    get :configuration
  end
end
