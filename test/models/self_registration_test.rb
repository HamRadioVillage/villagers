require "test_helper"

class SelfRegistrationTest < ActiveSupport::TestCase
  test "enabled by default when the env var is unset" do
    with_env("SELF_REGISTRATION_ENABLED" => nil) do
      assert SelfRegistration.enabled?
      assert_not SelfRegistration.disabled?
    end
  end

  test "disabled when the env var is a falsey value" do
    with_env("SELF_REGISTRATION_ENABLED" => "false") do
      assert_not SelfRegistration.enabled?
      assert SelfRegistration.disabled?
    end
  end

  test "enabled when the env var is a truthy value" do
    with_env("SELF_REGISTRATION_ENABLED" => "true") do
      assert SelfRegistration.enabled?
    end
  end
end
