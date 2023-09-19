object @users
node do |user|
  partial('api/v1/users/show', :object => user)
end

