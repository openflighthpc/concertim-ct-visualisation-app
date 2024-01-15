class CreateSettings < ActiveRecord::Migration[7.0]
  class Setting < ActiveRecord::Base ; end

  def change
    create_table :settings do |t|
      t.jsonb :settings, default: {}, null: false

      t.timestamps
    end

    reversible do |dir|
      dir.up do
        Setting.reset_column_information
        Setting.create!(settings: {metric_refresh_interval: 15})
      end
      dir.down do
        Setting.reset_column_information
        Setting.destroy_all
      end
    end
  end
end
