class CreateFleeceKeyPairs < ActiveRecord::Migration[7.0]
  def change
    reversible do |dir|
      dir.up   { execute 'SET search_path TO public, uma' }
    end

    create_table :fleece_key_pairs do |t|
      t.string :name,     limit: 255, null: false
      t.string :key_type, limit: 255, null: false

      t.timestamps
    end

    add_reference 'fleece_key_pairs', 'user', null: false, foreign_key: { on_update: :cascade, on_delete: :restrict }

    reversible do |dir|
      dir.down { execute 'SET search_path TO public, uma' }
    end
  end
end
