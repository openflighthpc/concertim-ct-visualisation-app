class RemoveDefaultOperatorUsers < ActiveRecord::Migration[7.0]
  module Ivy
    class HwRack < ActiveRecord::Base
      self.table_name = "racks"
      establish_connection :ivy
    end
  end

  module Uma
    class User < ActiveRecord::Base
      establish_connection :uma
      devise :database_authenticatable

      has_many :racks, class_name: 'Ivy::HwRack'
    end
  end

  def up
    remove_used_user(Uma::User.find_by(login: 'operator_one'))
    remove_used_user(Uma::User.find_by(login: 'operator_two'))
  end

  def down
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

  private

  def remove_used_user(u)
    if u.racks.empty?
      say "Removing user:#{u.id}(#{u.login} #{u.name})"
      u.destroy!
    else
      say "Not removing user:#{u.id}(#{u.login} #{u.name}), they own #{u.racks.map(&:name).join(', ')}"
    end
  end
end
