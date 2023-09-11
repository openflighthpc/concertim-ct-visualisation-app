class CreateDevice < ActiveRecord::Migration[7.0]
  def change
    create_table :devices do |t|
      t.string :name, limit: 255, null: false
      t.string :description, limit: 255
      t.string :type, limit: 255, null: false, default: 'Server'
      t.boolean :tagged, null: false, default: false
      t.boolean :hidden, null: false, default: false
      t.integer :modified_timestamp, null: false, default: 0

      t.timestamps
    end

    add_reference 'devices', 'slot',
      null: true,
      foreign_key: { on_update: :cascade, on_delete: :cascade }

    add_reference 'devices', 'base_chassis',
      null: true,
      foreign_key: { on_update: :cascade, on_delete: :cascade }
  end
end
