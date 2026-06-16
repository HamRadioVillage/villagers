require "test_helper"

class OauthIdentityTest < ActiveSupport::TestCase
  def auth(roles: [], email: "person@example.com", name: "A Person", uid: "uid-1", claim_key: "roles")
    OmniAuth::AuthHash.new(
      provider: "villager_oauth",
      uid: uid,
      info: { email: email, name: name },
      extra: { raw_info: { "email" => email, "name" => name, claim_key => roles } }
    )
  end

  test "exposes uid, email and name" do
    identity = OauthIdentity.new(auth(uid: "abc", email: "a@b.com", name: "Ann"))
    assert_equal "abc", identity.uid
    assert_equal "a@b.com", identity.email
    assert_equal "Ann", identity.name
  end

  test "roles returns the claim as an array of strings" do
    identity = OauthIdentity.new(auth(roles: %w[village_admin lead:dc32]))
    assert_equal %w[village_admin lead:dc32], identity.roles
  end

  test "roles is an empty array when the claim is missing" do
    bare = OmniAuth::AuthHash.new(provider: "villager_oauth", uid: "x", info: {})
    assert_equal [], OauthIdentity.new(bare).roles
  end

  test "roles reads the configurable claim key" do
    identity = OauthIdentity.new(auth(roles: %w[admin], claim_key: "current_roles"))
    with_env("OAUTH_ROLES_CLAIM" => "current_roles") do
      assert_equal %w[admin], identity.roles
    end
  end
end
