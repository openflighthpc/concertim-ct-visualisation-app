class SeedDefaultUsers < ActiveRecord::Migration[7.0]
  module Uma
    class User < ActiveRecord::Base
      establish_connection :uma
      devise :database_authenticatable
    end
  end

  def up
    Uma::User.create!(
      login: 'admin',
      firstname: 'System',
      surname: 'Administrator',
      email: 'admin@test.com',
      root: true,
      password: 'admin',
      password_confirmation: 'admin'
    )
    Uma::User.create!(
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
    Uma::User.destroy_all!
  end
end
