class CreateFleeceKeyPairs < ActiveRecord::Migration[7.0]
  def change
    create_table :fleece_key_pairs do |t|
      t.string :name,     limit: 255, null: false
      t.string :key_type, limit: 255, null: false
      t.string :fingerprint, limit: 255, null: false

      t.timestamps
    end

    add_reference 'fleece_key_pairs', 'user', null: false, foreign_key: { on_update: :cascade, on_delete: :restrict }
  end
end
