class CreateChassis < ActiveRecord::Migration[7.0]
  def change
    create_table 'base_chassis' do |t|
      t.string :name, limit: 255, null: false, default: ''
      t.integer :modified_timestamp, null: false, default: 0
      t.boolean :show_in_dcrv, null: false, default: false

      t.timestamps
    end

    add_reference 'base_chassis', 'template',
      null: false,
      foreign_key: { on_update: :cascade, on_delete: :restrict }
  end
end
