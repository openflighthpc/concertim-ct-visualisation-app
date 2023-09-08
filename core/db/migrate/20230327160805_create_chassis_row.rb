class CreateChassisRow < ActiveRecord::Migration[7.0]
  def change
    reversible do |dir|
      dir.up   { execute 'SET search_path TO ivy,public' }
    end

    create_table 'chassis_rows' do |t|
      t.integer :row_number, null: false, default: 1

      t.timestamps
    end

    add_reference 'chassis_rows', 'base_chassis',
      null: false,
      foreign_key: { on_update: :cascade, on_delete: :cascade }

    reversible do |dir|
      dir.down { execute 'SET search_path TO ivy,public' }
    end
  end
end
