class ChangeRackAssociations < ActiveRecord::Migration[7.0]
  def change
    remove_reference :racks, :user, null: false, type: :uuid, foreign_key: { on_update: :cascade, on_delete: :restrict }
    add_reference :racks, :team, null: false, type: :uuid, foreign_key: { on_update: :cascade, on_delete: :restrict }
  end
end
