class RemoveFleeceKeyPairs < ActiveRecord::Migration[7.0]
  def change
    reversible do |dir|
      dir.up   { execute 'SET search_path TO public, uma' }
    end

    drop_table :fleece_key_pairs

    reversible do |dir|
      dir.down { execute 'SET search_path TO public, uma' }
    end
  end
end
