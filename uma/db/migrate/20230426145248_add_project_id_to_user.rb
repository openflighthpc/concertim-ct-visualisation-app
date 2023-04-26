class AddProjectIdToUser < ActiveRecord::Migration[7.0]
  def change
    reversible do |dir|
      dir.up   { execute 'SET search_path TO uma,public' }
    end

    change_table :users do |t|
      t.string :project_id, null: true, limit: 255, index: { unique: true }
    end

    reversible do |dir|
      dir.down { execute 'SET search_path TO uma,public' }
    end
  end
end
