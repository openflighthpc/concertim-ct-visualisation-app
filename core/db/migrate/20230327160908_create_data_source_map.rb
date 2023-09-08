class CreateDataSourceMap < ActiveRecord::Migration[7.0]
  def change
    reversible do |dir|
      dir.up   { execute 'SET search_path TO ivy,public' }
    end

    create_table :data_source_maps do |t|
      t.string :map_to_grid, limit: 56, null: false
      t.string :map_to_cluster, limit: 56, null: false
      t.string :map_to_host, limit: 150, null: false

      t.timestamps
    end

    add_reference 'data_source_maps', 'device',
      null: false,
      foreign_key: { on_update: :cascade, on_delete: :cascade }

    reversible do |dir|
      dir.down { execute 'SET search_path TO ivy,public' }
    end
  end
end
