class AdjustDefaultUsers < ActiveRecord::Migration[7.0]
  class User < ActiveRecord::Base
    devise :database_authenticatable
  end

  def up
    User.find_by(login: 'operator').destroy!
    User.create!(
      login: 'operator_one',
      firstname: 'Operator',
      surname: 'One',
      email: 'operator_one@test.com',
      root: false,
      password: 'operator_one',
      password_confirmation: 'operator_one'
    )
    User.create!(
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
    User.find_by(login: 'operator_one').destroy!
    User.find_by(login: 'operator_two').destroy!
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
end
