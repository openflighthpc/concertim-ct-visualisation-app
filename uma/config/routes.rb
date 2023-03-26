Uma::Engine.routes.draw do
  devise_for :users, class_name: "Uma::User", only: [:sessions]
  as :user do
    get 'users/edit' => 'registrations#edit', :as => 'edit_user_registration'
    match 'users' => 'registrations#update', :as => 'user_registration', via: [:put, :patch]
  end
end
