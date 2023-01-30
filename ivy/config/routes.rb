Ivy::Engine.routes.draw do
  resource :irv, as: :'ivy_irv', only: :show do
    get :configuration
  end
end
