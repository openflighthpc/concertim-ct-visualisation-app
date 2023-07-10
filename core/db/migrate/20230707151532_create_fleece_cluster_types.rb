class CreateFleeceClusterTypes < ActiveRecord::Migration[7.0]
  def change
    reversible do |dir|
      dir.up   { execute 'SET search_path TO public' }
    end

    create_table :fleece_cluster_types do |t|
      t.string  :name,        null: false, limit: 255
      t.string  :description, null: false, limit: 1024
      t.string  :foreign_id,  null: false
      t.integer :nodes,       null: false, default: 1

      t.timestamps

      reversible do |dir|
        dir.down { execute 'SET search_path TO public' }
      end
    end
  end
end
