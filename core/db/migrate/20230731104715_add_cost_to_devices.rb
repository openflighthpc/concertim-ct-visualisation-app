class AddCostToDevices < ActiveRecord::Migration[7.0]
  def change
    reversible do |dir|
      dir.up   { execute 'SET search_path TO ivy,public' }
    end

    add_column :devices, :cost, :decimal, null: false, default: 0.00

    reversible do |dir|
      dir.down { execute 'SET search_path TO ivy,public' }
    end
  end
end
