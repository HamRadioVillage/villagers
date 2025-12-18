require "test_helper"

class NotificationTest < ActiveSupport::TestCase
  setup do
    @village = Village.create!(name: "Test Village", setup_complete: true)
    @user = User.create!(
      email: "test@example.com",
      password: "password123",
      password_confirmation: "password123"
    )
  end

  test "valid notification with required attributes" do
    notification = Notification.new(
      user: @user,
      title: "Test Notification",
      body: "This is a test notification body",
      notification_type: Notification::SHIFT_SIGNUP
    )
    assert notification.valid?
  end

  test "invalid without user" do
    notification = Notification.new(
      title: "Test",
      body: "Test body",
      notification_type: Notification::SHIFT_SIGNUP
    )
    assert_not notification.valid?
    assert_includes notification.errors[:user], "must exist"
  end

  test "invalid without title" do
    notification = Notification.new(
      user: @user,
      body: "Test body",
      notification_type: Notification::SHIFT_SIGNUP
    )
    assert_not notification.valid?
    assert_includes notification.errors[:title], "can't be blank"
  end

  test "invalid without body" do
    notification = Notification.new(
      user: @user,
      title: "Test",
      notification_type: Notification::SHIFT_SIGNUP
    )
    assert_not notification.valid?
    assert_includes notification.errors[:body], "can't be blank"
  end

  test "invalid without notification_type" do
    notification = Notification.new(
      user: @user,
      title: "Test",
      body: "Test body"
    )
    assert_not notification.valid?
    assert_includes notification.errors[:notification_type], "can't be blank"
  end

  test "invalid with unknown notification_type" do
    notification = Notification.new(
      user: @user,
      title: "Test",
      body: "Test body",
      notification_type: "invalid_type"
    )
    assert_not notification.valid?
    assert_includes notification.errors[:notification_type], "is not included in the list"
  end

  test "unread scope returns notifications without read_at" do
    @user.notifications.create!(title: "Read", body: "Read notification", notification_type: Notification::SYSTEM, read_at: Time.current)
    unread = @user.notifications.create!(title: "Unread", body: "Unread notification", notification_type: Notification::SYSTEM)

    assert_includes Notification.unread, unread
    assert_not_includes Notification.unread, @user.notifications.where(title: "Read").first
  end

  test "read scope returns notifications with read_at" do
    read = @user.notifications.create!(title: "Read", body: "Read notification", notification_type: Notification::SYSTEM, read_at: Time.current)
    @user.notifications.create!(title: "Unread", body: "Unread notification", notification_type: Notification::SYSTEM)

    assert_includes Notification.read, read
  end

  test "recent scope orders by created_at desc" do
    older = @user.notifications.create!(title: "Older", body: "Older notification", notification_type: Notification::SYSTEM, created_at: 1.day.ago)
    newer = @user.notifications.create!(title: "Newer", body: "Newer notification", notification_type: Notification::SYSTEM, created_at: Time.current)

    notifications = @user.notifications.recent
    assert_equal newer, notifications.first
    assert_equal older, notifications.second
  end

  test "old_read scope returns read notifications older than 30 days" do
    old_read = @user.notifications.create!(title: "Old Read", body: "Old read notification", notification_type: Notification::SYSTEM, read_at: 31.days.ago)
    new_read = @user.notifications.create!(title: "New Read", body: "New read notification", notification_type: Notification::SYSTEM, read_at: 1.day.ago)
    unread = @user.notifications.create!(title: "Unread", body: "Unread notification", notification_type: Notification::SYSTEM)

    old_read_notifications = Notification.old_read
    assert_includes old_read_notifications, old_read
    assert_not_includes old_read_notifications, new_read
    assert_not_includes old_read_notifications, unread
  end

  test "read? returns true when read_at is present" do
    notification = @user.notifications.create!(title: "Read", body: "Read notification", notification_type: Notification::SYSTEM, read_at: Time.current)
    assert notification.read?
  end

  test "read? returns false when read_at is nil" do
    notification = @user.notifications.create!(title: "Unread", body: "Unread notification", notification_type: Notification::SYSTEM)
    assert_not notification.read?
  end

  test "unread? returns true when read_at is nil" do
    notification = @user.notifications.create!(title: "Unread", body: "Unread notification", notification_type: Notification::SYSTEM)
    assert notification.unread?
  end

  test "unread? returns false when read_at is present" do
    notification = @user.notifications.create!(title: "Read", body: "Read notification", notification_type: Notification::SYSTEM, read_at: Time.current)
    assert_not notification.unread?
  end

  test "mark_as_read! sets read_at when unread" do
    notification = @user.notifications.create!(title: "Unread", body: "Unread notification", notification_type: Notification::SYSTEM)
    assert_nil notification.read_at

    notification.mark_as_read!
    notification.reload

    assert_not_nil notification.read_at
    assert notification.read?
  end

  test "mark_as_read! does not update read_at when already read" do
    original_read_at = 1.day.ago
    notification = @user.notifications.create!(title: "Read", body: "Read notification", notification_type: Notification::SYSTEM, read_at: original_read_at)

    notification.mark_as_read!
    notification.reload

    assert_in_delta original_read_at.to_i, notification.read_at.to_i, 1
  end

  test "all notification types are defined" do
    assert_equal [ "shift_signup", "shift_reminder", "shift_cancelled", "admin_alert", "system" ], Notification::TYPES
  end
end
