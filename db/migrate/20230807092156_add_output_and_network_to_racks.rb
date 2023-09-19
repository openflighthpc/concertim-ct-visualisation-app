class AddOutputAndNetworkToRacks < ActiveRecord::Migration[7.0]
  def change
    add_column :racks, :creation_output, :string
    add_column :racks, :network_details, :jsonb, null: false, default: {}
  end
end
