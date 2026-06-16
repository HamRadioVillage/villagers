require "test_helper"
require "minitest/mock"

class OauthAccessControlTest < ActionDispatch::IntegrationTest
  test "allows sign in when a role matches the configured pattern" do
    stub_villager_oauth(uid: "ok-1", email: "allowed@example.com", roles: %w[village_admin])

    VillagerOauthConfig.stub(:allowed_roles_pattern, /\Avillage_admin\z/) do
      assert_difference "User.count", 1 do
        get user_villager_oauth_omniauth_callback_path
      end
      assert_redirected_to root_path
    end
  end

  test "denies sign in and provisions nothing when no role matches" do
    stub_villager_oauth(uid: "no-1", email: "denied@example.com", roles: %w[volunteer])

    VillagerOauthConfig.stub(:allowed_roles_pattern, /\Avillage_admin\z/) do
      assert_no_difference "User.count" do
        get user_villager_oauth_omniauth_callback_path
      end
      assert_redirected_to new_user_session_path
      assert_match(/authorized/i, flash[:alert])
    end
  end

  test "allows sign in when no pattern is configured (gate off)" do
    stub_villager_oauth(uid: "open-1", email: "open@example.com", roles: [])

    VillagerOauthConfig.stub(:allowed_roles_pattern, nil) do
      assert_difference "User.count", 1 do
        get user_villager_oauth_omniauth_callback_path
      end
      assert_redirected_to root_path
    end
  end
end
