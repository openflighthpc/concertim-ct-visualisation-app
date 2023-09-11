class RemoveFleeceKeyPairs < ActiveRecord::Migration[7.0]
  def change
    drop_table :fleece_key_pairs
  end
end
