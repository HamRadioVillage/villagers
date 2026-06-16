require "test_helper"

class VillagerOauthConfigTest < ActiveSupport::TestCase
  def with_env(key, value)
    original = ENV[key]
    value.nil? ? ENV.delete(key) : ENV[key] = value
    yield
  ensure
    original.nil? ? ENV.delete(key) : ENV[key] = original
  end

  test "roles_claim defaults to 'roles'" do
    with_env("OAUTH_ROLES_CLAIM", nil) do
      assert_equal "roles", VillagerOauthConfig.roles_claim
    end
  end

  test "roles_claim is overridable" do
    with_env("OAUTH_ROLES_CLAIM", "current_roles") do
      assert_equal "current_roles", VillagerOauthConfig.roles_claim
    end
  end

  test "allowed_roles_pattern is nil when unset (gate off)" do
    with_env("OAUTH_ALLOWED_ROLES_REGEX", nil) do
      assert_nil VillagerOauthConfig.allowed_roles_pattern
    end
  end

  test "allowed_roles_pattern compiles a configured regex" do
    with_env("OAUTH_ALLOWED_ROLES_REGEX", '\Avillage_admin\z') do
      assert_equal(/\Avillage_admin\z/, VillagerOauthConfig.allowed_roles_pattern)
    end
  end

  test "allowed_roles_pattern raises on an invalid regex (fail fast at boot)" do
    with_env("OAUTH_ALLOWED_ROLES_REGEX", "[") do
      assert_raises(RegexpError) { VillagerOauthConfig.allowed_roles_pattern }
    end
  end
end
