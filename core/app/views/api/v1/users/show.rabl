object @user
attributes :id, :login, :name
node :fullname do |user|
  user.name
end
attribute :project_id, if: ->(user) { !user.root? }
