Rails.application.routes.draw do
  # Engines
  mount Ivy::Engine => '/', as: :ivy_engine
end
