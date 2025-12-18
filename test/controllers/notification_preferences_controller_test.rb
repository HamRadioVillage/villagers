require "test_helper"

class NotificationPreferencesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @village = Village.create!(name: "Test Village", setup_complete: true)
    @user = User.create!(
      email: "test@example.com",
      password: "password123",
      password_confirmation: "password123"
    )
    sign_in @user
  end

  test "should update notification preferences to enable both" do
    @user.update!(notify_by_email: false, notify_in_app: false)

    patch notification_preferences_path, params: {
      user: { notify_by_email: "1", notify_in_app: "1" }
    }

    assert_redirected_to edit_user_registration_path
    assert_equal "Notification preferences updated.", flash[:notice]

    @user.reload
    assert @user.notify_by_email?
    assert @user.notify_in_app?
  end

  test "should update notification preferences to disable both" do
    @user.update!(notify_by_email: true, notify_in_app: true)

    patch notification_preferences_path, params: {
      user: { notify_by_email: "0", notify_in_app: "0" }
    }

    assert_redirected_to edit_user_registration_path
    assert_equal "Notification preferences updated.", flash[:notice]

    @user.reload
    assert_not @user.notify_by_email?
    assert_not @user.notify_in_app?
  end

  test "should update notification preferences to enable only in-app" do
    patch notification_preferences_path, params: {
      user: { notify_by_email: "0", notify_in_app: "1" }
    }

    assert_redirected_to edit_user_registration_path

    @user.reload
    assert_not @user.notify_by_email?
    assert @user.notify_in_app?
  end

  test "should update notification preferences to enable only email" do
    patch notification_preferences_path, params: {
      user: { notify_by_email: "1", notify_in_app: "0" }
    }

    assert_redirected_to edit_user_registration_path

    @user.reload
    assert @user.notify_by_email?
    assert_not @user.notify_in_app?
  end

  test "requires authentication" do
    sign_out @user
    patch notification_preferences_path, params: {
      user: { notify_by_email: "1", notify_in_app: "1" }
    }
    assert_redirected_to new_user_session_path
  end
end
