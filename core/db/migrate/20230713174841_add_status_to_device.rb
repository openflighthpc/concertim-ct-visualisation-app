class AddStatusToDevice < ActiveRecord::Migration[7.0]
  def change
    add_column :devices, :status, :string, null: false, default: 'IN_PROGRESS'
    change_column_default :devices, :status, from: 'IN_PROGRESS', to: nil
  end
end
