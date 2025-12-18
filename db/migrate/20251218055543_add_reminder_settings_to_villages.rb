class AddReminderSettingsToVillages < ActiveRecord::Migration[8.1]
  def change
    add_column :villages, :reminder_hours_before, :integer, default: 24
  end
end
