class AddCostToUsers < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :cost, :decimal, null: false, default: 0.00
  end
end
