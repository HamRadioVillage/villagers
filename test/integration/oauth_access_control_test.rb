require "test_helper"

class OauthAccessControlTest < ActionDispatch::IntegrationTest
  test "allows sign in when a role matches the configured pattern" do
    stub_villager_oauth(uid: "ok-1", email: "allowed@example.com", roles: %w[village_admin])

    with_env("OAUTH_ALLOWED_ROLES_REGEX" => '\Avillage_admin\z') do
      assert_difference "User.count", 1 do
        get user_villager_oauth_omniauth_callback_path
      end
      assert_redirected_to root_path
    end
  end

  test "denies sign in and provisions nothing when no role matches" do
    stub_villager_oauth(uid: "no-1", email: "denied@example.com", roles: %w[volunteer])

    with_env("OAUTH_ALLOWED_ROLES_REGEX" => '\Avillage_admin\z') do
      assert_no_difference "User.count" do
        get user_villager_oauth_omniauth_callback_path
      end
      assert_redirected_to new_user_session_path
      assert_match(/authorized/i, flash[:alert])
    end
  end

  test "allows sign in when no pattern is configured (gate off)" do
    stub_villager_oauth(uid: "open-1", email: "open@example.com", roles: [])

    with_env("OAUTH_ALLOWED_ROLES_REGEX" => "") do
      assert_difference "User.count", 1 do
        get user_villager_oauth_omniauth_callback_path
      end
      assert_redirected_to root_path
    end
  end
end
