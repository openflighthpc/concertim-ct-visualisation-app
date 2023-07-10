object @user
attributes :id, :login, :name
node :fullname do |user|
  user.name
end
attribute :cloud_user_id, if: ->(user) { !user.root? }
attribute :project_id, if: ->(user) { !user.root? }
