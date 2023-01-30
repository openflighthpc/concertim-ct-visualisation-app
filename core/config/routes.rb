Rails.application.routes.draw do
  scope module: :ivy do
    resource :irv, as: :'ivy_irv', only: :show
  end

  # Engines
  mount Ivy::Engine => '/', as: :ivy_engine
end
