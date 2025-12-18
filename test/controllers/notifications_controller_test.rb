require "test_helper"

class NotificationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @village = Village.create!(name: "Test Village", setup_complete: true)
    @user = User.create!(
      email: "test@example.com",
      password: "password123",
      password_confirmation: "password123"
    )
    @other_user = User.create!(
      email: "other@example.com",
      password: "password123",
      password_confirmation: "password123"
    )
    @notification = @user.notifications.create!(
      title: "Test Notification",
      body: "Test notification body",
      notification_type: Notification::SYSTEM
    )
    sign_in @user
  end

  test "should get index" do
    get notifications_path
    assert_response :success
    assert_select "h1", /Inbox/
  end

  test "index shows unread count badge" do
    @user.notifications.create!(
      title: "Unread Notification",
      body: "Unread body",
      notification_type: Notification::SYSTEM
    )
    get notifications_path
    assert_response :success
    # Should show badge with count
    assert_select ".badge.bg-danger"
  end

  test "index does not show unread badge when all read" do
    @user.notifications.update_all(read_at: Time.current)
    get notifications_path
    assert_response :success
    # Should not show the unread badge in the title area
    assert_select "h1 .badge.bg-danger", count: 0
  end

  test "should get show and mark notification as read" do
    assert_nil @notification.read_at
    get notification_path(@notification)
    assert_response :success
    @notification.reload
    assert_not_nil @notification.read_at
  end

  test "show displays notification details" do
    get notification_path(@notification)
    assert_response :success
    assert_select "h1", @notification.title
    assert_select ".notification-body", /#{@notification.body}/
  end

  test "should mark all notifications as read" do
    unread1 = @user.notifications.create!(title: "Unread 1", body: "Body", notification_type: Notification::SYSTEM)
    unread2 = @user.notifications.create!(title: "Unread 2", body: "Body", notification_type: Notification::SYSTEM)

    assert_nil unread1.read_at
    assert_nil unread2.read_at

    post mark_all_read_notifications_path
    assert_redirected_to notifications_path
    assert_equal "All notifications marked as read.", flash[:notice]

    unread1.reload
    unread2.reload
    assert_not_nil unread1.read_at
    assert_not_nil unread2.read_at
  end

  test "should destroy notification" do
    assert_difference("Notification.count", -1) do
      delete notification_path(@notification)
    end
    assert_redirected_to notifications_path
    assert_equal "Notification deleted.", flash[:notice]
  end

  test "should bulk destroy notifications" do
    notification2 = @user.notifications.create!(
      title: "Another Notification",
      body: "Another body",
      notification_type: Notification::SYSTEM
    )

    assert_difference("Notification.count", -2) do
      delete bulk_destroy_notifications_path, params: { notification_ids: [ @notification.id, notification2.id ] }
    end
    assert_redirected_to notifications_path
    assert_equal "Selected notifications deleted.", flash[:notice]
  end

  test "cannot access other user notifications" do
    other_notification = @other_user.notifications.create!(
      title: "Other User Notification",
      body: "Body",
      notification_type: Notification::SYSTEM
    )

    get notification_path(other_notification)
    assert_response :not_found
  end

  test "cannot destroy other user notifications" do
    other_notification = @other_user.notifications.create!(
      title: "Other User Notification",
      body: "Body",
      notification_type: Notification::SYSTEM
    )

    assert_no_difference("Notification.count") do
      delete notification_path(other_notification)
    end
    assert_response :not_found
  end

  test "requires authentication for index" do
    sign_out @user
    get notifications_path
    assert_redirected_to new_user_session_path
  end

  test "requires authentication for show" do
    sign_out @user
    get notification_path(@notification)
    assert_redirected_to new_user_session_path
  end
end
