class AddCostToRacks < ActiveRecord::Migration[7.0]
  def change
    add_column :racks, :cost, :decimal, null: false, default: 0.00
  end
end
