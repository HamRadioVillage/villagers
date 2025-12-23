require "application_system_test_case"

class DemoModeSystemTest < ApplicationSystemTestCase
  setup do
    @original_demo_mode = ENV["DEMO_MODE"]
  end

  teardown do
    ENV["DEMO_MODE"] = @original_demo_mode
  end

  test "demo banner is displayed when demo mode is enabled" do
    ENV["DEMO_MODE"] = "true"

    visit root_path

    assert_selector ".demo-banner", text: /Demo Mode/
  end

  test "demo banner is not displayed when demo mode is disabled" do
    ENV["DEMO_MODE"] = "false"

    visit root_path

    assert_no_selector ".demo-banner"
  end

  test "demo credentials are shown on login page when demo mode enabled" do
    ENV["DEMO_MODE"] = "true"

    visit new_user_session_path

    assert_selector ".demo-credentials"
    assert_text "admin@example.com"
    assert_text "password"
  end

  test "demo credentials are not shown on login page when demo mode disabled" do
    ENV["DEMO_MODE"] = "false"

    visit new_user_session_path

    assert_no_selector ".demo-credentials"
  end
end
