class AddFieldsToFleeceClusterTypes < ActiveRecord::Migration[7.0]
  def change
    add_column :fleece_cluster_types, :fields, :jsonb, null: false, default: {}
    remove_column :fleece_cluster_types, :nodes, :integer, null: false, default: 1
  end
end
