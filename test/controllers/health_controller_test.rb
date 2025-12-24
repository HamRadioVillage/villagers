require "test_helper"

class HealthControllerTest < ActionDispatch::IntegrationTest
  setup do
    @original_demo_mode = ENV["DEMO_MODE"]
    @timestamp_file = Rails.root.join("tmp", "demo_last_reset.txt")
    @original_timestamp = File.read(@timestamp_file) if File.exist?(@timestamp_file)
  end

  teardown do
    ENV["DEMO_MODE"] = @original_demo_mode

    # Restore or clean up timestamp file
    if @original_timestamp
      File.write(@timestamp_file, @original_timestamp)
    elsif File.exist?(@timestamp_file)
      File.delete(@timestamp_file)
    end
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

  test "health check includes demo mode status when enabled with reset recorded" do
    ENV["DEMO_MODE"] = "true"
    File.write(@timestamp_file, 1.hour.ago.utc.iso8601)

    get health_path, as: :json

    json = JSON.parse(response.body)
    assert json["demo_mode"]
    assert json.key?("next_reset")
    assert json.key?("time_until_reset")
  end

  test "health check shows demo mode without reset info when no reset recorded" do
    ENV["DEMO_MODE"] = "true"
    File.delete(@timestamp_file) if File.exist?(@timestamp_file)

    get health_path, as: :json

    json = JSON.parse(response.body)
    assert json["demo_mode"]
    assert_not json.key?("next_reset")
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
