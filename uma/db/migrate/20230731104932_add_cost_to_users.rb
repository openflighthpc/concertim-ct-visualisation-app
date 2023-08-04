class AddCostToUsers < ActiveRecord::Migration[7.0]
  def change
    reversible do |dir|
      dir.up   { execute 'SET search_path TO uma,public' }
    end

    add_column :users, :cost, :decimal, null: false, default: 0.00

    reversible do |dir|
      dir.down { execute 'SET search_path TO uma,public' }
    end
  end
end
