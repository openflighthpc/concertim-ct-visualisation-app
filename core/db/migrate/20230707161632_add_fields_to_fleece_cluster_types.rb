class AddFieldsToFleeceClusterTypes < ActiveRecord::Migration[7.0]
  def change
    reversible do |dir|
      dir.up   { execute 'SET search_path TO public' }
    end

    add_column :fleece_cluster_types, :fields, :jsonb, null: false, default: {}
    remove_column :fleece_cluster_types, :nodes, :integer, null: false, default: 1

    reversible do |dir|
      dir.down   { execute 'SET search_path TO public' }
    end
  end
end
