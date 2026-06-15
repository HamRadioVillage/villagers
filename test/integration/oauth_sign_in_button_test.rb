require "test_helper"
require "minitest/mock"

class OauthSignInButtonTest < ActionDispatch::IntegrationTest
  # OAuth is enabled in the test environment (dummy creds set in test_helper).
  test "sign-in page shows the OAuth button when configured" do
    get new_user_session_path
    assert_response :success
    assert_select "form[action=?]", user_villager_oauth_omniauth_authorize_path
  end

  test "sign-up page shows the OAuth button when configured" do
    get new_user_registration_path
    assert_response :success
    assert_select "form[action=?]", user_villager_oauth_omniauth_authorize_path
  end

  test "sign-in page renders without the OAuth button when not configured" do
    VillagerOauthConfig.stub(:enabled?, false) do
      get new_user_session_path
      assert_response :success
      assert_select "form[action=?]", user_villager_oauth_omniauth_authorize_path, count: 0
    end
  end
end
