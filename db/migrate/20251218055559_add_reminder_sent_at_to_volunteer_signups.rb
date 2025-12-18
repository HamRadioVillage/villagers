class AddReminderSentAtToVolunteerSignups < ActiveRecord::Migration[8.1]
  def change
    add_column :volunteer_signups, :reminder_sent_at, :datetime
  end
end
