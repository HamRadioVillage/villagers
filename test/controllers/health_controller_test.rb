require "test_helper"

class HealthControllerTest < ActionDispatch::IntegrationTest
  setup do
    @original_demo_mode = ENV["DEMO_MODE"]
  end

  teardown do
    ENV["DEMO_MODE"] = @original_demo_mode
  end

  test "health check returns 200" do
    get health_path

    assert_response :success
  end

  test "health check returns JSON" do
    get health_path, as: :json

    assert_response :success
    json = JSON.parse(response.body)
    assert json.key?("status")
    assert_equal "ok", json["status"]
  end

  test "health check includes demo mode status when enabled" do
    ENV["DEMO_MODE"] = "true"

    get health_path, as: :json

    json = JSON.parse(response.body)
    assert json["demo_mode"]
    assert json.key?("next_reset")
  end

  test "health check shows demo mode false when disabled" do
    ENV["DEMO_MODE"] = "false"

    get health_path, as: :json

    json = JSON.parse(response.body)
    assert_not json["demo_mode"]
    assert_nil json["next_reset"]
  end

  test "health check includes database connectivity" do
    get health_path, as: :json

    json = JSON.parse(response.body)
    assert json.key?("database")
  end
end
