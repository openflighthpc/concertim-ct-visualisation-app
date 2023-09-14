class AddVersionToClusterTypes < ActiveRecord::Migration[7.0]
  def change
    add_column :cluster_types, :version, :datetime
  end
end
