class AddMetadataFieldsToTemplate < ActiveRecord::Migration[7.0]
  def change
    add_column :templates, :foreign_id, :string,  null: true
    add_column :templates, :vcpus,      :integer, null: true
    add_column :templates, :ram,        :integer, null: true
    add_column :templates, :disk,       :integer, null: true
  end
end
