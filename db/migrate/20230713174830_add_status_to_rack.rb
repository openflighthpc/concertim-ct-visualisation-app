class AddStatusToRack < ActiveRecord::Migration[7.0]
  def change
    add_column :racks, :status, :string, null: false, default: 'IN_PROGRESS'
    change_column_default :racks, :status, from: 'IN_PROGRESS', to: nil
  end
end
