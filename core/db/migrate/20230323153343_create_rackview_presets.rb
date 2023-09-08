class CreateRackviewPresets < ActiveRecord::Migration[7.0]
  def change
    create_table 'meca.rackview_presets' do |t|
      t.string :name, limit: 255, null: false
      t.boolean :default, null: false, default: false
      t.jsonb :values
      t.integer :user_id
      t.boolean :global, null: false, default: false

      t.timestamps
    end
  end
end
