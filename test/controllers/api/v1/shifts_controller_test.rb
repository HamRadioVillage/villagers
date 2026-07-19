require "test_helper"

class Api::V1::ShiftsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @village = Village.create!(name: "Test Village", setup_complete: true)
    @conference = Conference.create!(
      village: @village,
      name: "Test Conference",
      start_date: Date.tomorrow,
      end_date: Date.tomorrow + 2.days,
      conference_hours_start: "09:00",
      conference_hours_end: "17:00"
    )
    @program = Program.create!(name: "Test Program", village: @village)
    @other_program = Program.create!(name: "Other Program", village: @village)
    @conference_program = ConferenceProgram.create!(conference: @conference, program: @program)
    @other_conference_program = ConferenceProgram.create!(conference: @conference, program: @other_program)

    @volunteer = create_confirmed_user(email: "volunteer@example.com")
    @volunteer2 = create_confirmed_user(email: "volunteer2@example.com")
    @lead = create_confirmed_user(email: "lead@example.com")
    ConferenceRole.create!(user: @lead, conference: @conference, role_name: ConferenceRole::CONFERENCE_LEAD)

    @timeslot_9am = Timeslot.create!(
      conference_program: @conference_program,
      start_time: Date.tomorrow.to_datetime + 9.hours,
      max_volunteers: 2
    )
    @timeslot_10am = Timeslot.create!(
      conference_program: @conference_program,
      start_time: Date.tomorrow.to_datetime + 10.hours,
      max_volunteers: 2
    )
    @other_program_timeslot = Timeslot.create!(
      conference_program: @other_conference_program,
      start_time: Date.tomorrow.to_datetime + 11.hours,
      max_volunteers: 2
    )

    @signup_10am = VolunteerSignup.create!(user: @volunteer, timeslot: @timeslot_10am)
    @signup_9am = VolunteerSignup.create!(user: @volunteer, timeslot: @timeslot_9am)
    @other_user_signup = VolunteerSignup.create!(user: @volunteer2, timeslot: @timeslot_9am)
    @other_program_signup = VolunteerSignup.create!(user: @volunteer, timeslot: @other_program_timeslot)

    @token = @volunteer.api_tokens.create!(name: "test token")
    @lead_token = @lead.api_tokens.create!(name: "lead token")
  end

  def bearer(token)
    { "Authorization" => "Bearer #{token.plaintext_token}" }
  end

  test "returns 401 without credentials" do
    get api_v1_conference_shifts_url(@conference)
    assert_response :unauthorized
  end

  test "volunteer sees only their own signups ordered by start time" do
    get api_v1_conference_shifts_url(@conference), headers: bearer(@token)
    assert_response :success
    json = JSON.parse(response.body)

    assert_equal @conference.id, json["conference_id"]
    signups = json["shifts"]
    assert_equal 3, signups.size
    assert_equal [ @signup_9am.id, @signup_10am.id, @other_program_signup.id ], signups.map { |s| s["id"] }

    first = signups.first
    assert_equal @volunteer.id, first["user_id"]
    assert_equal "Test Program", first["program"]
    assert_equal @timeslot_9am.start_time.utc.iso8601, first["starts_at"]
    assert_equal @timeslot_9am.end_time.utc.iso8601, first["ends_at"]
  end

  test "volunteer requesting another user_id gets 403" do
    get api_v1_conference_shifts_url(@conference, user_id: @volunteer2.id),
        headers: bearer(@token)
    assert_response :forbidden
  end

  test "conference lead sees all signups and may filter by user_id" do
    get api_v1_conference_shifts_url(@conference), headers: bearer(@lead_token)
    assert_equal 4, JSON.parse(response.body)["shifts"].size

    get api_v1_conference_shifts_url(@conference, user_id: @volunteer2.id),
        headers: bearer(@lead_token)
    signups = JSON.parse(response.body)["shifts"]
    assert_equal [ @other_user_signup.id ], signups.map { |s| s["id"] }
  end

  test "filters by program_id" do
    get api_v1_conference_shifts_url(@conference, program_id: @other_program.id),
        headers: bearer(@token)
    signups = JSON.parse(response.body)["shifts"]
    assert_equal [ @other_program_signup.id ], signups.map { |s| s["id"] }
  end

  test "filters by from and to timestamps" do
    from = (Date.tomorrow.to_datetime + 9.hours + 30.minutes).utc.iso8601
    get api_v1_conference_shifts_url(@conference, from: from), headers: bearer(@token)
    signups = JSON.parse(response.body)["shifts"]
    assert_equal [ @signup_10am.id, @other_program_signup.id ], signups.map { |s| s["id"] }

    to = (Date.tomorrow.to_datetime + 9.hours + 30.minutes).utc.iso8601
    get api_v1_conference_shifts_url(@conference, to: to), headers: bearer(@token)
    signups = JSON.parse(response.body)["shifts"]
    assert_equal [ @signup_9am.id ], signups.map { |s| s["id"] }
  end

  test "returns 400 for an unparseable from/to" do
    get api_v1_conference_shifts_url(@conference, from: "not-a-date"),
        headers: bearer(@token)
    assert_response :bad_request
    assert_equal "invalid_date", JSON.parse(response.body)["error"]
  end

  test "returns 404 for an unknown conference" do
    get api_v1_conference_shifts_url(conference_id: 999_999), headers: bearer(@token)
    assert_response :not_found
  end
end
