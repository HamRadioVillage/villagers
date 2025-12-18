require "test_helper"

class CleanupOldNotificationsJobTest < ActiveJob::TestCase
  setup do
    @village = Village.create!(name: "Test Village", setup_complete: true)
    @user = User.create!(
      email: "test@example.com",
      password: "password123",
      password_confirmation: "password123"
    )
  end

  test "deletes read notifications older than 30 days" do
    old_read = @user.notifications.create!(
      title: "Old Read",
      body: "Old read notification",
      notification_type: Notification::SYSTEM,
      read_at: 31.days.ago
    )

    assert_difference("Notification.count", -1) do
      CleanupOldNotificationsJob.perform_now
    end

    assert_not Notification.exists?(old_read.id)
  end

  test "does not delete read notifications less than 30 days old" do
    new_read = @user.notifications.create!(
      title: "New Read",
      body: "New read notification",
      notification_type: Notification::SYSTEM,
      read_at: 29.days.ago
    )

    assert_no_difference("Notification.count") do
      CleanupOldNotificationsJob.perform_now
    end

    assert Notification.exists?(new_read.id)
  end

  test "does not delete unread notifications" do
    unread = @user.notifications.create!(
      title: "Unread",
      body: "Unread notification",
      notification_type: Notification::SYSTEM
    )

    assert_no_difference("Notification.count") do
      CleanupOldNotificationsJob.perform_now
    end

    assert Notification.exists?(unread.id)
  end

  test "deletes multiple old notifications" do
    3.times do |i|
      @user.notifications.create!(
        title: "Old Read #{i}",
        body: "Old read notification",
        notification_type: Notification::SYSTEM,
        read_at: (31 + i).days.ago
      )
    end

    assert_difference("Notification.count", -3) do
      CleanupOldNotificationsJob.perform_now
    end
  end
end
