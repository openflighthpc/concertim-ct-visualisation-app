class AddStatusToDevice < ActiveRecord::Migration[7.0]
  def change
    reversible do |dir|
      dir.up   { execute 'SET search_path TO ivy,public' }
    end

    add_column :devices, :status, :string, null: false, default: 'IN_PROGRESS'
    change_column_default :devices, :status, from: 'IN_PROGRESS', to: nil

    reversible do |dir|
      dir.down { execute 'SET search_path TO ivy,public' }
    end
  end
end
