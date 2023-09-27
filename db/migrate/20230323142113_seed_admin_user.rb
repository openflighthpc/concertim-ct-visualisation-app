class SeedAdminUser < ActiveRecord::Migration[7.0]

  class User < ActiveRecord::Base
    devise :database_authenticatable
  end

  def up
    User.reset_column_information
    User.create!(
      login: 'admin',
      name: 'System Administrator',
      email: 'admin@test.com',
      root: true,
      password: 'admin',
      password_confirmation: 'admin'
    )
  end

  def down
    User.reset_column_information
    User.destroy_all!
  end
end
