class AddClusterBuilderPortToCloudServiceConfig < ActiveRecord::Migration[7.0]
  def change
    add_column :cloud_service_configs, :cluster_builder_port, :integer, default: 42378, null: false
  end
end
