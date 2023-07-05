class AddUserHandlerPortToFleeceConfig < ActiveRecord::Migration[7.0]
  reversible do |dir|
    dir.up   { execute 'SET search_path TO public' }
  end

  def change
    add_column :fleece_configs, :user_handler_port, :integer, default: 42356, null: false
  end

  reversible do |dir|
    dir.down   { execute 'SET search_path TO public' }
  end
end
