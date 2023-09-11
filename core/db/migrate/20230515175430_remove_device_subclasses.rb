class RemoveDeviceSubclasses < ActiveRecord::Migration[7.0]
  def change
    change_table :devices do |t|
      t.remove :type, type: :string, limit: 255, null: false, default: 'Server'
    end
  end
end
