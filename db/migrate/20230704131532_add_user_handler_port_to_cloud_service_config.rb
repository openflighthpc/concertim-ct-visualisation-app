class AddUserHandlerPortToCloudServiceConfig < ActiveRecord::Migration[7.0]
  def change
    add_column :cloud_service_configs, :user_handler_port, :integer, default: 42356, null: false
  end
end
