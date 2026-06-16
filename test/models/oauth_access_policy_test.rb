require "test_helper"

class OauthAccessPolicyTest < ActiveSupport::TestCase
  def identity(roles)
    OauthIdentity.new(
      OmniAuth::AuthHash.new(
        provider: "villager_oauth",
        uid: "uid",
        info: { email: "p@example.com", name: "P" },
        extra: { raw_info: { "roles" => roles } }
      )
    )
  end

  test "permits everyone when no pattern is configured (gate off)" do
    with_env("OAUTH_ALLOWED_ROLES_REGEX" => "") do
      assert OauthAccessPolicy.permitted?(identity([]))
      assert OauthAccessPolicy.permitted?(identity(%w[anything]))
    end
  end

  test "permits when a role matches the pattern" do
    with_env("OAUTH_ALLOWED_ROLES_REGEX" => '\Avillage_admin\z') do
      assert OauthAccessPolicy.permitted?(identity(%w[volunteer village_admin]))
    end
  end

  test "denies when no role matches the pattern" do
    with_env("OAUTH_ALLOWED_ROLES_REGEX" => '\Avillage_admin\z') do
      assert_not OauthAccessPolicy.permitted?(identity(%w[volunteer guest]))
    end
  end

  test "denies (fail closed) when roles are empty but a pattern is configured" do
    with_env("OAUTH_ALLOWED_ROLES_REGEX" => '\Avillage_admin\z') do
      assert_not OauthAccessPolicy.permitted?(identity([]))
    end
  end

  test "supports prefix patterns against scoped role strings" do
    with_env("OAUTH_ALLOWED_ROLES_REGEX" => '\Alead:') do
      assert OauthAccessPolicy.permitted?(identity(%w[lead:dc32]))
      assert_not OauthAccessPolicy.permitted?(identity(%w[admin:dc32]))
    end
  end
end
