Rails.application.routes.draw do
  scope module: :ivy do
    resource :irv, as: :'ivy_irv', only: :show
  end
end
