class DevicesCannotBeTagged < ActiveRecord::Migration[7.0]
  def change
    change_table :devices do |t|
      t.remove :tagged, type: :boolean, default: false, null: false
    end
  end
end
