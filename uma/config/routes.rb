Uma::Engine.routes.draw do
  devise_for :users, class_name: "Uma::User"
end
