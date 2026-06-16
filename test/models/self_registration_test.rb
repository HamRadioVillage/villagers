require "test_helper"

class SelfRegistrationTest < ActiveSupport::TestCase
  def with_env(value)
    original = ENV["SELF_REGISTRATION_ENABLED"]
    if value.nil?
      ENV.delete("SELF_REGISTRATION_ENABLED")
    else
      ENV["SELF_REGISTRATION_ENABLED"] = value
    end
    yield
  ensure
    ENV["SELF_REGISTRATION_ENABLED"] = original
  end

  test "enabled by default when the env var is unset" do
    with_env(nil) do
      assert SelfRegistration.enabled?
      assert_not SelfRegistration.disabled?
    end
  end

  test "disabled when the env var is a falsey value" do
    with_env("false") do
      assert_not SelfRegistration.enabled?
      assert SelfRegistration.disabled?
    end
  end

  test "enabled when the env var is a truthy value" do
    with_env("true") do
      assert SelfRegistration.enabled?
    end
  end
end
