class CreateClusterTypes < ActiveRecord::Migration[7.0]
  def change
    create_table :cluster_types do |t|
      t.string  :name,        null: false, limit: 255
      t.string  :description, null: false, limit: 1024
      t.string  :foreign_id,  null: false
      t.jsonb :fields, default: {}, null: false
      t.datetime :version

      t.timestamps
    end
  end
end
