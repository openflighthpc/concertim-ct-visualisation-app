class AddOrderAndLogoUrlToClusterType < ActiveRecord::Migration[7.1]
  def change
    add_column :cluster_types, :order, :integer, null: false, default: 0
    add_column :cluster_types, :logo_url, :string, limit: 255
  end
end
