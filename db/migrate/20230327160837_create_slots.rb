class CreateSlots < ActiveRecord::Migration[7.0]
  def change
    create_table 'slots' do |t|
      t.integer :chassis_row_location, null: false, default: 1

      t.timestamps
    end

    add_reference 'slots', 'chassis_row',
      null: false,
      foreign_key: { on_update: :cascade, on_delete: :cascade }
  end
end
