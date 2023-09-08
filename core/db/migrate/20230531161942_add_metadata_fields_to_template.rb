class AddMetadataFieldsToTemplate < ActiveRecord::Migration[7.0]
  def change
    reversible do |dir|
      dir.up   { execute 'SET search_path TO ivy,public' }
    end

    add_column :templates, :foreign_id, :string,  null: true
    add_column :templates, :vcpus,      :integer, null: true
    add_column :templates, :ram,        :integer, null: true
    add_column :templates, :disk,       :integer, null: true

    reversible do |dir|
      dir.down { execute 'SET search_path TO ivy,public' }
    end
  end
end
