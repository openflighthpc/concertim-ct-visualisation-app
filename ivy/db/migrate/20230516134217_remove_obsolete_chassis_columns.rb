class RemoveObsoleteChassisColumns < ActiveRecord::Migration[7.0]
  def up
    change_table :base_chassis do |t|
      t.remove "u_height",     type: :integer, default: 1,   null: false
      t.remove "u_depth",      type: :integer, default: 2,   null: false
      t.remove "facing",       type: :string,  default: "f", null: false
      t.remove "rack_start_u", type: :integer,               null: false
      t.remove "rack_end_u",   type: :integer,               null: false
      t.remove "slot_population_order", type: :string, limit: 8, default: "lr-bt", null: false
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
