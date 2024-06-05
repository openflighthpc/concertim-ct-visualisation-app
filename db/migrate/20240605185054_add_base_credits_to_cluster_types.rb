class AddBaseCreditsToClusterTypes < ActiveRecord::Migration[7.1]
  def up
    add_column :cluster_types, :base_credits, :integer
  end
end
