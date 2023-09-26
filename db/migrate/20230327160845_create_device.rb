class CreateDevice < ActiveRecord::Migration[7.0]
  def change
    create_table :devices do |t|
      t.string :name, limit: 255, null: false
      t.string :description, limit: 255
      t.boolean :hidden, null: false, default: false
      t.integer :modified_timestamp, null: false, default: 0
      t.jsonb :metadata, default: {}, null: false
      t.string :status, null: false
      t.decimal :cost, default: 0.0, null: false
      t.string :public_ips
      t.string :private_ips
      t.string :ssh_key
      t.string :login_user
      t.jsonb :volume_details, default: {}, null: false

      t.timestamps
    end

    add_reference 'devices', 'base_chassis',
      null: false,
      foreign_key: { on_update: :cascade, on_delete: :cascade }
  end
end
