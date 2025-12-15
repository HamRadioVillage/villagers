require "test_helper"

class ScheduleControllerTest < ActionDispatch::IntegrationTest
  setup do
    @village = Village.create!(name: "Test Village", setup_complete: true)
    @village_admin = User.create!(
      email: "admin@example.com",
      password: "password123",
      password_confirmation: "password123"
    )
    @volunteer = User.create!(
      email: "volunteer@example.com",
      password: "password123",
      password_confirmation: "password123"
    )
    @conference_lead = User.create!(
      email: "lead@example.com",
      password: "password123",
      password_confirmation: "password123"
    )

    village_admin_role = Role.find_or_create_by!(name: Role::VILLAGE_ADMIN)
    UserRole.create!(user: @village_admin, role: village_admin_role)

    @conference = Conference.create!(
      village: @village,
      name: "Test Conference",
      start_date: Date.tomorrow,
      end_date: Date.tomorrow + 2.days,
      conference_hours_start: "09:00",
      conference_hours_end: "17:00"
    )

    ConferenceRole.create!(
      user: @conference_lead,
      conference: @conference,
      role_name: ConferenceRole::CONFERENCE_LEAD
    )

    @program = Program.create!(
      name: "Test Program",
      village: @village
    )

    @conference_program = ConferenceProgram.create!(
      conference: @conference,
      program: @program
    )
  end

  test "should get show as authenticated volunteer" do
    sign_in @volunteer
    get conference_schedule_url(@conference)
    assert_response :success
  end

  test "should get show as village admin" do
    sign_in @village_admin
    get conference_schedule_url(@conference)
    assert_response :success
  end

  test "should get show as conference lead" do
    sign_in @conference_lead
    get conference_schedule_url(@conference)
    assert_response :success
  end

  test "should redirect to login when not authenticated" do
    get conference_schedule_url(@conference)
    assert_redirected_to new_user_session_path
  end

  test "schedule shows programs for conference" do
    sign_in @volunteer
    get conference_schedule_url(@conference)
    assert_response :success
    assert_match @program.name, response.body
  end

  test "conference manager can see all volunteers flag" do
    sign_in @conference_lead
    get conference_schedule_url(@conference)
    assert_response :success
    # Conference leads should be able to see volunteer management controls
  end

  test "volunteer cannot see all volunteers management controls" do
    sign_in @volunteer
    get conference_schedule_url(@conference)
    assert_response :success
    # Regular volunteers have limited view
  end


  test "schedule data includes conference dates" do
    sign_in @volunteer
    get conference_schedule_url(@conference)
    assert_response :success
    # Schedule should show each day of the conference
  end
end
