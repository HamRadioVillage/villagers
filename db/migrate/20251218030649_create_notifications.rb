class CreateNotifications < ActiveRecord::Migration[8.1]
  def change
    create_table :notifications do |t|
      t.references :user, null: false, foreign_key: true
      t.string :title, null: false
      t.text :body, null: false
      t.string :notification_type, null: false
      t.datetime :read_at

      t.timestamps
    end

    # Index for fetching user's notifications ordered by date
    add_index :notifications, [ :user_id, :created_at ], order: { created_at: :desc }
    # Index for cleanup job (find read notifications older than 30 days)
    add_index :notifications, :read_at
  end
end
