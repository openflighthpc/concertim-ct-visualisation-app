class MergeUserFirstAndLastName < ActiveRecord::Migration[7.0]
  module Uma
    class User < ActiveRecord::Base
      establish_connection :uma
      devise :database_authenticatable
    end
  end

  def change
    reversible do |dir|
      dir.up   { execute 'SET search_path TO uma,public' }
    end

    reversible do |dir|
      dir.up do
        # Append surname to new firstname column.
        Uma::User.reset_column_information
        Uma::User.all.each do |user|
          say "Updating user #{user.firstname} #{user.surname}"
          user.firstname += " #{user.surname}"
          user.save!
        end
      end

      dir.down do
        # Extract surname from name column as best we can.
        Uma::User.reset_column_information
        Uma::User.all.each do |user|
          say "Updating user #{user.firstname}"
          parts = user.firstname.slit(' ')
          user.firstname = parts[0...-1].join(' ')
          user.surname = parts[-1]
          user.save!
        end
        change_column_null :users, :surname, false
      end
    end

    change_table :users do |t|
      t.rename :firstname, :name
    end

    change_table :users do |t|
      t.remove :surname, limit: 56, null: true
    end

    reversible do |dir|
      dir.down { execute 'SET search_path TO uma,public' }
    end
  end
end
