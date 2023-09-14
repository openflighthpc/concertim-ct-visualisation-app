class AddProjectIdToUser < ActiveRecord::Migration[7.0]
  def change
    change_table :users do |t|
      t.string :project_id, null: true, limit: 255, index: { unique: true }
    end
  end
end
