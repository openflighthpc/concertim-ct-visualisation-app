class AddBillingPeriodToUsers < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :billing_period_start, :date
    add_column :users, :billing_period_end, :date
  end
end
