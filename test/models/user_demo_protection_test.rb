require "test_helper"

class UserDemoProtectionTest < ActiveSupport::TestCase
  setup do
    @original_demo_mode = ENV["DEMO_MODE"]
  end

  teardown do
    ENV["DEMO_MODE"] = @original_demo_mode
  end

  test "protected demo account cannot be destroyed when demo mode enabled" do
    ENV["DEMO_MODE"] = "true"

    user = User.new(
      email: "admin@example.com",
      password: "password",
      password_confirmation: "password"
    )
    user.skip_confirmation!
    user.save!

    assert_not user.destroy
    assert user.errors[:base].any? { |e| e.include?("demo") }
    assert User.exists?(user.id)
  end

  test "protected demo account can be destroyed when demo mode disabled" do
    ENV["DEMO_MODE"] = "false"

    user = User.new(
      email: "admin@example.com",
      password: "password",
      password_confirmation: "password"
    )
    user.skip_confirmation!
    user.save!

    assert user.destroy
    assert_not User.exists?(user.id)
  end

  test "non-demo account can be destroyed when demo mode enabled" do
    ENV["DEMO_MODE"] = "true"

    user = User.new(
      email: "random@example.com",
      password: "password",
      password_confirmation: "password"
    )
    user.skip_confirmation!
    user.save!

    assert user.destroy
    assert_not User.exists?(user.id)
  end

  test "demo_protected? returns true for protected emails in demo mode" do
    ENV["DEMO_MODE"] = "true"

    user = User.new(email: "admin@example.com")
    assert user.demo_protected?
  end

  test "demo_protected? returns false for protected emails when demo disabled" do
    ENV["DEMO_MODE"] = "false"

    user = User.new(email: "admin@example.com")
    assert_not user.demo_protected?
  end

  test "demo_protected? returns false for non-demo emails" do
    ENV["DEMO_MODE"] = "true"

    user = User.new(email: "random@example.com")
    assert_not user.demo_protected?
  end
end
