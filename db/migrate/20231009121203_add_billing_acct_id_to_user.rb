class AddBillingAcctIdToUser < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :billing_acct_id, :string, limit: 255
    add_index  :users, :billing_acct_id, unique: true, where: "NOT NULL"
  end
end
