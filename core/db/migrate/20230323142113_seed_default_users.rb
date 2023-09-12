class SeedDefaultUsers < ActiveRecord::Migration[7.0]

  class User < ActiveRecord::Base
    devise :database_authenticatable
  end

  def up
    User.reset_column_information
    User.create!(
      login: 'admin',
      firstname: 'System',
      surname: 'Administrator',
      email: 'admin@test.com',
      root: true,
      password: 'admin',
      password_confirmation: 'admin'
    )
    User.create!(
      login: 'operator',
      firstname: 'Normal',
      surname: 'Operator',
      email: 'operator@test.com',
      root: false,
      password: 'operator',
      password_confirmation: 'operator'
    )
  end

  def down
    User.reset_column_information
    User.destroy_all!
  end
end
