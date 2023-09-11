class AddCostToDevices < ActiveRecord::Migration[7.0]
  def change
    add_column :devices, :cost, :decimal, null: false, default: 0.00
  end
end
