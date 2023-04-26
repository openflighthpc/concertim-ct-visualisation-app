object @user
attributes :login, :name, :project_id
node :fullname do |user|
  user.name
end
