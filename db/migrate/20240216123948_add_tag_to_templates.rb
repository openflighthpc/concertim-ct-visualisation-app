class AddTagToTemplates < ActiveRecord::Migration[7.1]
  def change
    add_column :templates, :tag, :string, null: true
    add_index :templates, :tag, unique: true
  end
end
