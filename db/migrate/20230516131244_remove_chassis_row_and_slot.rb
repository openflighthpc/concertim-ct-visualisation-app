class RemoveChassisRowAndSlot < ActiveRecord::Migration[7.0]
  def up
    remove_reference 'devices', 'slot',
      null: true,
      foreign_key: { on_update: :cascade, on_delete: :cascade }

    remove_reference 'slots', 'chassis_row',
      null: false,
      foreign_key: { on_update: :cascade, on_delete: :cascade }

    remove_reference 'chassis_rows', 'base_chassis',
      null: false,
      foreign_key: { on_update: :cascade, on_delete: :cascade }

    remove_reference 'base_chassis', 'rack',
      null: false,
      foreign_key: { on_update: :cascade, on_delete: :restrict }

    drop_table 'chassis_rows'
    drop_table 'slots'
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
