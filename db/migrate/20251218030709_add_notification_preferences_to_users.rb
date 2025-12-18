class AddNotificationPreferencesToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :notify_by_email, :boolean, default: true, null: false
    add_column :users, :notify_in_app, :boolean, default: true, null: false
  end
end
