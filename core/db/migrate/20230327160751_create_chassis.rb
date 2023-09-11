class CreateChassis < ActiveRecord::Migration[7.0]
  def change
    create_table 'base_chassis' do |t|
      t.string :name, limit: 255, null: false, default: ''
      t.integer :u_height, null: false, default: 1
      t.integer :u_depth, null: false, default: 2
      t.string :facing, null: false, default: 'f'
      t.integer :rack_start_u, null: false
      t.integer :rack_end_u, null: false
      t.string :slot_population_order, limit: 8, null: false, default: 'lr-bt'
      t.string :type, limit: 255, null: false
      t.integer :modified_timestamp, null: false, default: 0
      t.boolean :show_in_dcrv, null: false, default: false

      t.timestamps
    end

    add_reference 'base_chassis', 'rack',
      null: false,
      foreign_key: { on_update: :cascade, on_delete: :restrict }

    add_reference 'base_chassis', 'template',
      null: false,
      foreign_key: { on_update: :cascade, on_delete: :restrict }
  end
end
