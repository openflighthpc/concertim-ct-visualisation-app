class FixUserProjectIdUniqueConstraint < ActiveRecord::Migration[7.0]
  def change
    reversible do |dir|
      dir.up   { execute 'SET search_path TO uma,public' }
    end

    remove_index "uma.users", "project_id", unique: true
    add_index "uma.users", "project_id", unique: true, where: "NOT NULL"

    reversible do |dir|
      dir.down { execute 'SET search_path TO uma,public' }
    end
  end
end
