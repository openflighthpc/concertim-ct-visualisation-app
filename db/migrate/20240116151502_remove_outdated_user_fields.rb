class RemoveOutdatedUserFields < ActiveRecord::Migration[7.0]
  def change
    remove_index  :users, :billing_acct_id, unique: true, where: "NOT NULL"
    remove_index  :users, :project_id, unique: true, where: "NOT NULL"
    remove_column :users, :project_id, :string, limit: 255
    remove_column :users, :billing_acct_id, :string, limit: 255
    remove_column :users, :billing_period_start, :date
    remove_column :users, :billing_period_end, :date
    remove_column :users, :cost, :decimal, default: 0.00, null: false
  end
end
