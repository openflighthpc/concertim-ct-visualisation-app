class AddUserHandlerPortToFleeceConfig < ActiveRecord::Migration[7.0]
  def change
    add_column :fleece_configs, :user_handler_port, :integer, default: 42356, null: false
  end
end
