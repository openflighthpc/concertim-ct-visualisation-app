class RemoveOrderFromRacks < ActiveRecord::Migration[7.1]
  def change
    remove_column :racks, :order_id, :string
  end
end
