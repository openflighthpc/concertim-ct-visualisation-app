class AddClusterTypeToRacks < ActiveRecord::Migration[7.1]
  class HwRack < ApplicationRecord
    self.table_name = "racks"
  end

  def up
    HwRack.destroy_all
    add_reference :racks, :cluster_type, type: :uuid, null:false, foreign_key: { on_delete: :restrict }
  end

  def down
    remove_reference :racks, :cluster_type, type: :uuid, null:false, foreign_key: { on_delete: :restrict }
  end
end
