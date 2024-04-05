class DestroyRacks < ActiveRecord::Migration[7.1]
  def up
    HwRack.destroy_all
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
