class FixUserProjectIdUniqueConstraint < ActiveRecord::Migration[7.0]
  def change
    remove_index "users", "project_id", unique: true
    add_index "users", "project_id", unique: true, where: "NOT NULL"
  end
end
