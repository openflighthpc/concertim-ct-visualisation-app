class AddMetadataToRacks < ActiveRecord::Migration[7.0]
  def change
    reversible do |dir|
      dir.up   { execute 'SET search_path TO ivy,uma,public' }
    end

    add_column :racks, :metadata, :jsonb, default: {}, null: false

    reversible do |dir|
      dir.down { execute 'SET search_path TO ivy,uma,public' }
    end
  end
end
