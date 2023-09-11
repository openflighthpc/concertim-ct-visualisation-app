class AddVersionToFleeceClusterTypes < ActiveRecord::Migration[7.0]
  def change
    add_column :fleece_cluster_types, :version, :datetime
  end
end
