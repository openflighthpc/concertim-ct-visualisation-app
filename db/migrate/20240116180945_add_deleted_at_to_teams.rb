class AddDeletedAtToTeams < ActiveRecord::Migration[7.0]
  def change
    add_column :teams, :deleted_at, :datetime
    add_index :teams, :deleted_at,
              where: 'deleted_at IS NOT NULL',
              name: 'teams_deleted_at_not_null'
    add_index :teams, :deleted_at,
              where: 'deleted_at IS NULL',
              name: 'teams_deleted_at_null'
  end
end
