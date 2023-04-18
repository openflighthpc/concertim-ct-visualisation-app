class AddUserIdToRack < ActiveRecord::Migration[7.0]
  def change
    reversible do |dir|
      dir.up   { execute 'SET search_path TO ivy,uma,public' }
    end

    add_reference 'racks', 'user',
      null: false,
      foreign_key: { on_update: :cascade, on_delete: :restrict }

    reversible do |dir|
      dir.down { execute 'SET search_path TO ivy,uma,public' }
    end
  end
end
