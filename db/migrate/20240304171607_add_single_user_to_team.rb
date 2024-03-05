class AddSingleUserToTeam < ActiveRecord::Migration[7.1]
  def change
    add_column :teams, :single_user, :boolean, default: false, null: false
  end
end
