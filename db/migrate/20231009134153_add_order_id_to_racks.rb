class AddOrderIdToRacks < ActiveRecord::Migration[7.0]
  def change
    add_column :racks, :order_id, :string
    add_index  :racks, :order_id, unique: true
  end
end
