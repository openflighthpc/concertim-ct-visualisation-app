class AddDeletedAtToUser < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :deleted_at, :datetime
    add_index :users, :deleted_at,
      where: 'deleted_at IS NOT NULL',
      name: 'users_deleted_at_not_null'
    add_index :users, :deleted_at,
      where: 'deleted_at IS NULL',
      name: 'users_deleted_at_null'
  end
end
