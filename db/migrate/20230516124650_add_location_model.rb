class AddLocationModel < ActiveRecord::Migration[7.0]
  def change
    create_table 'locations' do |t|
      t.integer :u_depth, null: false, default: 2
      t.integer :u_height, null: false, default: 1
      t.integer :start_u, null: false
      t.integer :end_u, null: false
      t.string :facing, null: false, default: 'f'

      t.timestamps
    end

    add_reference 'locations', 'rack',
      null: false,
      foreign_key: { on_update: :cascade, on_delete: :restrict }

    # Later migrations will populate location data and make this column `null:
    # false`.
    add_reference 'base_chassis', 'location',
      null: true,
      foreign_key: { on_update: :cascade, on_delete: :restrict }

    # Later migrations will populate chassis_id data and make this column `null:
    # false`.
    add_reference 'devices', 'base_chassis',
      null: true,
      foreign_key: { on_update: :cascade, on_delete: :cascade }
  end
end
