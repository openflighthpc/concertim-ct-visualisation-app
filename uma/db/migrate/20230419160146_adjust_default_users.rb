class AdjustDefaultUsers < ActiveRecord::Migration[7.0]
  module Uma
    class User < ActiveRecord::Base
      establish_connection :uma
      devise :database_authenticatable
    end
  end

  def up
    Uma::User.find_by(login: 'operator').destroy!
    Uma::User.create!(
      login: 'operator_one',
      firstname: 'Operator',
      surname: 'One',
      email: 'operator_one@test.com',
      root: false,
      password: 'operator_one',
      password_confirmation: 'operator_one'
    )
    Uma::User.create!(
      login: 'operator_two',
      firstname: 'Operator',
      surname: 'Two',
      email: 'operator_two@test.com',
      root: false,
      password: 'operator_two',
      password_confirmation: 'operator_two'
    )
  end

  def down
    Uma::User.find_by(login: 'operator_one').destroy!
    Uma::User.find_by(login: 'operator_two').destroy!
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
end
