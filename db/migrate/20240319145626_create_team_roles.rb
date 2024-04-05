class CreateTeamRoles < ActiveRecord::Migration[7.0]
  def change
    create_table :team_roles, id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
      t.references :user, type: :uuid, foreign_key: true
      t.references :team, type: :uuid, foreign_key: true
      t.string :role, null: false

      t.timestamps
    end

    add_index :team_roles, [:user_id, :team_id], unique: true
  end
end
