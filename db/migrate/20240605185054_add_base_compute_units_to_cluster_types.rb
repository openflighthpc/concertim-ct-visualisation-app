class AddBaseComputeUnitsToClusterTypes < ActiveRecord::Migration[7.1]
  def up
    add_column :cluster_types, :base_compute_units, :integer
  end
end
