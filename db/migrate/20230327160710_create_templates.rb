class CreateTemplates < ActiveRecord::Migration[7.0]
  def change
    create_table 'templates' do |t|
      t.string :name, limit: 255, null: false, default: ''
      t.integer :height, null: false
      t.integer :depth, null: false
      t.integer :version, null: false, default: 1
      t.string :template_type, limit: 255, null: false
      t.integer :rackable, null: false, default: 1
      t.boolean :simple, null: false, default: true
      t.string :description, limit: 255
      t.jsonb :images, null: false, default: {}
      t.integer :rows
      t.integer :columns
      t.integer :padding_left, null: false, default: 0
      t.integer :padding_bottom, null: false, default: 0
      t.integer :padding_right, null: false, default: 0
      t.integer :padding_top, null: false, default: 0
      t.string :foreign_id
      t.integer :vcpus
      t.integer :ram
      t.integer :disk

      # Needed for IRV structure.  Should be removed eventually.
      t.string :model, limit: 255
      t.string :rack_repeat_ratio, limit: 255

      t.timestamps
    end
  end
end
