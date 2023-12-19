class AddCreditsToUsers < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :credits, :decimal, default: "0.0", null: false
  end
end
