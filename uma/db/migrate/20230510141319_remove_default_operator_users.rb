class RemoveDefaultOperatorUsers < ActiveRecord::Migration[7.0]
  module Ivy
    class HwRack < ActiveRecord::Base
      self.table_name = "racks"
    end
  end

  module Uma
    class User < ActiveRecord::Base
      devise :database_authenticatable

      has_many :racks, class_name: 'Ivy::HwRack'
    end
  end

  def up
    execute 'SET search_path TO ivy,uma,public'
    Uma::User.reset_column_information
    remove_unused_user(Uma::User.find_by(login: 'operator_one'))
    remove_unused_user(Uma::User.find_by(login: 'operator_two'))
  end

  def down
    execute 'SET search_path TO ivy,uma,public'
    Uma::User.reset_column_information
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

  def remove_unused_user(u)
    if u.racks.empty?
      say "Removing user:#{u.id}(#{u.login} #{u.name})"
      u.destroy!
    else
      say "Not removing user:#{u.id}(#{u.login} #{u.name}), they own #{u.racks.map(&:name).join(', ')}"
    end
  end
end
