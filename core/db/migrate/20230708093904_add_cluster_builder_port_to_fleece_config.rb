class AddClusterBuilderPortToFleeceConfig < ActiveRecord::Migration[7.0]
  def change
    reversible do |dir|
      dir.up   { execute 'SET search_path TO public' }
    end

    add_column :fleece_configs, :cluster_builder_port, :integer, default: 42378, null: false

    reversible do |dir|
      dir.down   { execute 'SET search_path TO public' }
    end
  end
end
