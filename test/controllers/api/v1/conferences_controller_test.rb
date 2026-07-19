require "test_helper"

class Api::V1::ConferencesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @village = Village.create!(name: "Test Village", setup_complete: true)
    @conference = Conference.create!(
      village: @village,
      name: "Test Conference",
      city: "Las Vegas",
      state: "NV",
      country: "US",
      start_date: Date.tomorrow,
      end_date: Date.tomorrow + 2.days,
      conference_hours_start: "09:00",
      conference_hours_end: "17:00"
    )
    @archived_conference = Conference.create!(
      village: @village,
      name: "Old Conference",
      start_date: Date.current - 30.days,
      end_date: Date.current - 28.days,
      conference_hours_start: "09:00",
      conference_hours_end: "17:00",
      archived_at: Time.current
    )

    @user = create_confirmed_user(email: "volunteer@example.com")
    @token = @user.api_tokens.create!(name: "test token")
  end

  def bearer(token)
    { "Authorization" => "Bearer #{token.plaintext_token}" }
  end

  test "returns 401 without credentials" do
    get api_v1_conferences_url
    assert_response :unauthorized
  end

  test "lists all conferences with event-level details" do
    get api_v1_conferences_url, headers: bearer(@token)
    assert_response :success
    json = JSON.parse(response.body)

    assert_equal 2, json["conferences"].size
    entry = json["conferences"].find { |c| c["id"] == @conference.id }
    assert_equal "Test Conference", entry["name"]
    assert_equal "Las Vegas", entry["city"]
    assert_equal "NV", entry["state"]
    assert_equal "US", entry["country"]
    assert_equal Date.tomorrow.iso8601, entry["start_date"]
    assert_equal (Date.tomorrow + 2.days).iso8601, entry["end_date"]
    assert_equal "09:00", entry["hours_start"]
    assert_equal "17:00", entry["hours_end"]
    assert_equal false, entry["archived"]
  end

  test "marks archived conferences" do
    get api_v1_conferences_url, headers: bearer(@token)
    entry = JSON.parse(response.body)["conferences"].find { |c| c["id"] == @archived_conference.id }
    assert_equal true, entry["archived"]
  end

  test "orders conferences by start date descending" do
    get api_v1_conferences_url, headers: bearer(@token)
    ids = JSON.parse(response.body)["conferences"].map { |c| c["id"] }
    assert_equal [ @conference.id, @archived_conference.id ], ids
  end
end
