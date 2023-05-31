class AddMetadataToDevice < ActiveRecord::Migration[7.0]
  def change
    reversible do |dir|
      dir.up   { execute 'SET search_path TO ivy,public' }
    end

    add_column :devices, :metadata, :jsonb, default: {}, null: false

    reversible do |dir|
      dir.down { execute 'SET search_path TO ivy,public' }
    end
  end
end
