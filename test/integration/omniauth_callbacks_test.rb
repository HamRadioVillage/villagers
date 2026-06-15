require "test_helper"

class OmniauthCallbacksTest < ActionDispatch::IntegrationTest
  test "successful callback signs in and creates a user" do
    stub_villager_oauth(uid: "cb-uid-1", email: "callback@example.com", name: "Callback User")

    assert_difference "User.count", 1 do
      get user_villager_oauth_omniauth_callback_path
    end

    assert_redirected_to root_path
    follow_redirect!
    assert_select "body" # rendered an authenticated page without redirecting to login
    assert_equal "callback@example.com", User.last.email
  end

  test "successful callback signs in an existing identity without creating a user" do
    stub_villager_oauth(uid: "cb-uid-2", email: "repeat@example.com")
    get user_villager_oauth_omniauth_callback_path

    delete destroy_user_session_path

    stub_villager_oauth(uid: "cb-uid-2", email: "repeat@example.com")
    assert_no_difference "User.count" do
      get user_villager_oauth_omniauth_callback_path
    end
    assert_redirected_to root_path
  end

  test "failed callback redirects to sign in with an alert" do
    stub_villager_oauth_failure(:invalid_credentials)

    get user_villager_oauth_omniauth_callback_path

    assert_redirected_to new_user_session_path
    assert flash[:alert].present?
  end
end
