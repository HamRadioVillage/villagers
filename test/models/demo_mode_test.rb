require "test_helper"

class DemoModeTest < ActiveSupport::TestCase
  setup do
    @original_demo_mode = ENV["DEMO_MODE"]
    @original_reset_hour = ENV["DEMO_RESET_HOUR"]
    @original_banner_text = ENV["DEMO_BANNER_TEXT"]
  end

  teardown do
    ENV["DEMO_MODE"] = @original_demo_mode
    ENV["DEMO_RESET_HOUR"] = @original_reset_hour
    ENV["DEMO_BANNER_TEXT"] = @original_banner_text
  end

  test "enabled? returns false by default" do
    ENV["DEMO_MODE"] = nil
    refute DemoMode.enabled?
  end

  test "enabled? returns true when DEMO_MODE is true" do
    ENV["DEMO_MODE"] = "true"
    assert DemoMode.enabled?
  end

  test "enabled? returns false when DEMO_MODE is false" do
    ENV["DEMO_MODE"] = "false"
    refute DemoMode.enabled?
  end

  test "disabled? is inverse of enabled?" do
    ENV["DEMO_MODE"] = "true"
    refute DemoMode.disabled?

    ENV["DEMO_MODE"] = "false"
    assert DemoMode.disabled?
  end

  test "protected_email? returns true for seed demo emails" do
    assert DemoMode.protected_email?("admin@example.com")
    assert DemoMode.protected_email?("coordinator@example.com")
    assert DemoMode.protected_email?("admin1@example.com")
    assert DemoMode.protected_email?("admin2@example.com")
    assert DemoMode.protected_email?("volunteer1@example.com")
    assert DemoMode.protected_email?("volunteer5@example.com")
  end

  test "protected_email? returns false for non-demo emails" do
    refute DemoMode.protected_email?("random@example.com")
    refute DemoMode.protected_email?("test@test.com")
  end

  test "protected_email? is case insensitive" do
    assert DemoMode.protected_email?("ADMIN@EXAMPLE.COM")
    assert DemoMode.protected_email?("Admin@Example.Com")
  end

  test "demo_credentials returns list of demo accounts" do
    credentials = DemoMode.demo_credentials

    assert credentials.is_a?(Array)
    assert credentials.any? { |c| c[:email] == "admin@example.com" }
    assert credentials.any? { |c| c[:role] == "Village Admin" }
    assert credentials.all? { |c| c[:password] == "password" }
  end

  test "reset_hour returns configured hour" do
    ENV["DEMO_RESET_HOUR"] = "6"
    assert_equal 6, DemoMode.reset_hour
  end

  test "reset_hour defaults to 4" do
    ENV["DEMO_RESET_HOUR"] = nil
    assert_equal 4, DemoMode.reset_hour
  end

  test "banner_text returns configured text" do
    ENV["DEMO_BANNER_TEXT"] = "Custom Demo Text"
    assert_equal "Custom Demo Text", DemoMode.banner_text
  end

  test "banner_text returns default when not configured" do
    ENV["DEMO_BANNER_TEXT"] = nil
    ENV["DEMO_RESET_HOUR"] = "4"
    assert_match(/Demo Mode/, DemoMode.banner_text)
    assert_match(/4:00 AM UTC/, DemoMode.banner_text)
  end

  test "next_reset_time returns future time" do
    ENV["DEMO_RESET_HOUR"] = "4"
    next_reset = DemoMode.next_reset_time
    assert next_reset > Time.current
  end

  test "time_until_reset returns positive duration" do
    ENV["DEMO_RESET_HOUR"] = "4"
    assert DemoMode.time_until_reset > 0
  end

  test "formatted_time_until_reset returns readable string" do
    ENV["DEMO_RESET_HOUR"] = "4"
    formatted = DemoMode.formatted_time_until_reset
    assert formatted.is_a?(String)
    assert formatted.match?(/\d+[hm]/)
  end
end
