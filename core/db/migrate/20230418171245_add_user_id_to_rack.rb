class AddUserIdToRack < ActiveRecord::Migration[7.0]
  def change
    add_reference 'racks', 'user',
      null: false,
      foreign_key: { on_update: :cascade, on_delete: :restrict }
  end
end
