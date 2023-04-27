object @user
attributes :id, :login, :name, :project_id
node :fullname do |user|
  user.name
end
