class CreateRacks < ActiveRecord::Migration[7.0]
  def change
    create_table 'racks' do |t|
      t.string :name, limit: 255, null: false
      t.integer :u_height, null: false, default: 42
      t.integer :u_depth, null: false, default: 2
      t.integer :modified_timestamp, null: false, default: 0
      t.jsonb :metadata, default: {}, null: false
      t.string :status, null: false
      t.decimal :cost, default: "0.0", null: false
      t.string :creation_output
      t.jsonb :network_details, default: {}, null: false

      t.timestamps
    end

    add_reference 'racks', 'template',
      null: false,
      foreign_key: { on_update: :cascade, on_delete: :restrict }
  end
end
