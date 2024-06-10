class RemoveCosts < ActiveRecord::Migration[7.1]
  def change
    remove_column :devices, :cost, :decimal, default: 0.0, null: false
    remove_column :racks, :cost, :decimal, default: 0.0, null: false
    remove_column :teams, :cost, :decimal, default: 0.0, null: false
    remove_column :teams, :credits, :decimal, default: 0.0, null: false
    remove_column :teams, :billing_period_start, :date
    remove_column :teams, :billing_period_end, :date
  end
end
