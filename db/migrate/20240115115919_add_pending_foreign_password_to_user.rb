class AddPendingForeignPasswordToUser < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :pending_foreign_password, :string
  end
end
