class AddBillingPeriodToUsers < ActiveRecord::Migration[7.0]
  def change
    reversible do |dir|
      dir.up   { execute 'SET search_path TO uma,public' }
    end

    add_column :users, :billing_period_start, :date
    add_column :users, :billing_period_end, :date

    reversible do |dir|
      dir.down { execute 'SET search_path TO uma,public' }
    end
  end
end
