object @user
attributes :id, :login, :name
node :fullname do |user|
  user.name
end
attribute :email
attribute :cloud_user_id, if: ->(user) { !user.root? }
attribute :project_id, if: ->(user) { !user.root? }
attribute :cost, if: ->(user) { !user.root? }
attribute :billing_period_start, if: ->(user) { !user.root? }
attribute :billing_period_end, if: ->(user) { !user.root? }
attribute root?: :root
