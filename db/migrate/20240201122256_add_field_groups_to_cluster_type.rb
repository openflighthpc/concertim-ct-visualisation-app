class AddFieldGroupsToClusterType < ActiveRecord::Migration[7.1]
  def change
    add_column :cluster_types, :field_groups, :jsonb, default: [], null: false
  end
end
