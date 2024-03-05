class AddLaunchInstructionToClusterType < ActiveRecord::Migration[7.1]
  def change
    add_column :cluster_types, :instructions, :jsonb
  end
end
