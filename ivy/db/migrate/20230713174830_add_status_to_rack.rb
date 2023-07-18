class AddStatusToRack < ActiveRecord::Migration[7.0]
  def change
    reversible do |dir|
      dir.up   { execute 'SET search_path TO ivy,public' }
    end

    add_column :racks, :status, :string, null: false, default: 'IN_PROGRESS'
    change_column_default :racks, :status, from: 'IN_PROGRESS', to: nil

    reversible do |dir|
      dir.down { execute 'SET search_path TO ivy,public' }
    end
  end
end
