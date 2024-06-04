class AddHourlyCreditsAndAliasToTemplates < ActiveRecord::Migration[7.1]
  def change
    add_column :templates, :hourly_credits, :integer
    add_column :templates, :alias, :string, limit: 255
  end
end
