class CreateCreditDeposits < ActiveRecord::Migration[7.1]
  def change
    create_table :credit_deposits, id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
      t.integer :amount, null: false
      t.references :team, type: :uuid, foreign_key: true, null: false, index: true
      t.date :date, null: false

      t.timestamps
    end
  end
end
