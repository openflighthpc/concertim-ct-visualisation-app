class AddOutputAndNetworkToRacks < ActiveRecord::Migration[7.0]
  def change
    reversible do |dir|
      dir.up   { execute 'SET search_path TO ivy,public' }
    end

    add_column :racks, :creation_output, :string
    add_column :racks, :network_details, :jsonb, null: false, default: {}

    reversible do |dir|
      dir.down { execute 'SET search_path TO ivy,public' }
    end
  end
end
