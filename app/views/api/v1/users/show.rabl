object @user
attributes :id, :login, :name
node :fullname do |user|
  user.name
end
attribute :email
attribute :cloud_user_id, if: ->(user) { !user.root? }
attribute root?: :root
attribute :status

child :team_roles do
  extends 'api/v1/team_roles/show'
end
