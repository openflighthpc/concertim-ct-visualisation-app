class CreateTeams < ActiveRecord::Migration[7.0]
  def change
    create_table :teams, id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
      t.string :name, limit: 255, null: false
      t.string :project_id, limit: 255
      t.string :billing_acct_id, limit: 255
      t.decimal :cost, default: 0.00, null: false
      t.decimal :credits, default: 0.00, null: false
      t.date :billing_period_start
      t.date :billing_period_end
      t.datetime :deleted_at

      t.timestamps
    end

    add_index  :teams, :billing_acct_id, unique: true, where: "NOT NULL"
    add_index :teams, :project_id, unique: true, where: "NOT NULL"
    add_index :teams, :deleted_at,
              where: 'deleted_at IS NOT NULL',
              name: 'teams_deleted_at_not_null'
    add_index :teams, :deleted_at,
              where: 'deleted_at IS NULL',
              name: 'teams_deleted_at_null'
  end
end
