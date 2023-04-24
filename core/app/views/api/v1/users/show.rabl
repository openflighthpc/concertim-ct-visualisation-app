object @user
attributes :login, :name
node :fullname do |user|
  user.name
end
