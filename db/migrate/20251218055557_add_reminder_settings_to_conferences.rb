class AddReminderSettingsToConferences < ActiveRecord::Migration[8.1]
  def change
    add_column :conferences, :reminder_hours_before, :integer
  end
end
