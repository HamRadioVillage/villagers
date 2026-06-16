require "test_helper"
require "minitest/mock"

class RegistrationDisabledTest < ActionDispatch::IntegrationTest
  # --- Self-registration enabled (default) ---------------------------------

  test "sign-up page is reachable when self-registration is enabled" do
    get new_user_registration_path
    assert_response :success
    assert_select "form[action=?]", user_registration_path
  end

  test "creating an account works when self-registration is enabled" do
    assert_difference "User.count", 1 do
      post user_registration_path, params: {
        user: { email: "newbie@example.com", password: "password123", password_confirmation: "password123" }
      }
    end
  end

  # --- Self-registration disabled ------------------------------------------

  test "sign-up page redirects to sign in when self-registration is disabled" do
    SelfRegistration.stub(:enabled?, false) do
      get new_user_registration_path
      assert_redirected_to new_user_session_path
      assert flash[:alert].present?
    end
  end

  test "creating an account is blocked when self-registration is disabled" do
    SelfRegistration.stub(:enabled?, false) do
      assert_no_difference "User.count" do
        post user_registration_path, params: {
          user: { email: "blocked@example.com", password: "password123", password_confirmation: "password123" }
        }
      end
      assert_redirected_to new_user_session_path
    end
  end

  test "sign-up link is hidden on the login page when self-registration is disabled" do
    SelfRegistration.stub(:enabled?, false) do
      get new_user_session_path
      assert_response :success
      assert_select "a[href=?]", new_user_registration_path, count: 0
    end
  end

  # --- OAuth account creation is unaffected --------------------------------

  test "OAuth account creation still works when self-registration is disabled" do
    auth = OmniAuth::AuthHash.new(
      provider: "villager_oauth",
      uid: "noselfreg-1",
      info: { email: "viasso@example.com", name: "Via SSO" }
    )

    SelfRegistration.stub(:enabled?, false) do
      assert_difference "User.count", 1 do
        user = User.from_omniauth(auth)
        assert user.persisted?
        assert_equal "viasso@example.com", user.email
      end
    end
  end
end
