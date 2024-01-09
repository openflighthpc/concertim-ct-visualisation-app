class CreateTeams < ActiveRecord::Migration[7.0]
  def change
    create_table :teams, id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
      t.string :name, limit: 255, null: false
      t.string :project_id, limit: 255
      t.string :billing_acct_id, limit: 255

      t.timestamps
    end
  end
end
