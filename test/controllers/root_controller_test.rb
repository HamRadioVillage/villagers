require "test_helper"

class RootControllerTest < ActionDispatch::IntegrationTest
  def setup
    @village = Village.create!(name: "Test Village", setup_complete: true)
  end

  test "should get root when setup is complete" do
    get root_url
    assert_response :success
  end

  test "should redirect root to setup when setup is not complete" do
    Village.destroy_all
    get root_url
    assert_redirected_to setup_url
  end

  test "should get root when signed in" do
    user = User.create!(
      email: "user@example.com",
      password: "password123",
      password_confirmation: "password123"
    )
    sign_in user
    get root_url
    assert_response :success
  end

  test "should show conference lead dashboard card when user is conference lead" do
    conference = Conference.create!(
      name: "Test Conference",
      village: @village,
      start_date: Date.tomorrow,
      end_date: Date.tomorrow + 3.days
    )
    user = User.create!(
      email: "lead@example.com",
      password: "password123",
      password_confirmation: "password123"
    )
    ConferenceRole.create!(
      user: user,
      conference: conference,
      role_name: ConferenceRole::CONFERENCE_LEAD
    )

    sign_in user
    get root_url

    assert_response :success
    assert_select "h2", text: /My Conferences/
    assert_select ".card-header", text: /Test Conference/
  end

  test "should not show conference lead dashboard card when user is not a conference lead" do
    user = User.create!(
      email: "volunteer@example.com",
      password: "password123",
      password_confirmation: "password123"
    )

    sign_in user
    get root_url

    assert_response :success
    assert_select ".card-header", text: /My Conferences/, count: 0
  end

  test "should show multiple conferences when user is lead of multiple conferences" do
    conference1 = Conference.create!(
      name: "Conference Alpha",
      village: @village,
      start_date: Date.tomorrow,
      end_date: Date.tomorrow + 3.days
    )
    conference2 = Conference.create!(
      name: "Conference Beta",
      village: @village,
      start_date: Date.tomorrow + 7.days,
      end_date: Date.tomorrow + 10.days
    )
    user = User.create!(
      email: "multlead@example.com",
      password: "password123",
      password_confirmation: "password123"
    )
    ConferenceRole.create!(user: user, conference: conference1, role_name: ConferenceRole::CONFERENCE_LEAD)
    ConferenceRole.create!(user: user, conference: conference2, role_name: ConferenceRole::CONFERENCE_LEAD)

    sign_in user
    get root_url

    assert_response :success
    assert_select ".card-header", text: /Conference Alpha/
    assert_select ".card-header", text: /Conference Beta/
  end

  test "should not show conference lead card for unauthenticated users" do
    get root_url

    assert_response :success
    assert_select ".card-header", text: /My Conferences/, count: 0
  end

  # Village Admin Dashboard Tests
  test "village admin sees admin dashboard section" do
    user = User.create!(
      email: "admin@example.com",
      password: "password123",
      password_confirmation: "password123"
    )
    admin_role = Role.find_or_create_by!(name: Role::VILLAGE_ADMIN)
    UserRole.create!(user: user, role: admin_role)

    sign_in user
    get root_url

    assert_response :success
    assert_select "h2", text: /Village Administration/
    assert_select ".card-header", text: /Quick Actions/
  end

  test "village admin sees upcoming conferences card" do
    Conference.create!(
      name: "Upcoming Con",
      village: @village,
      start_date: Date.tomorrow,
      end_date: Date.tomorrow + 3.days
    )
    user = User.create!(
      email: "admin@example.com",
      password: "password123",
      password_confirmation: "password123"
    )
    admin_role = Role.find_or_create_by!(name: Role::VILLAGE_ADMIN)
    UserRole.create!(user: user, role: admin_role)

    sign_in user
    get root_url

    assert_response :success
    assert_select ".card-header", text: /Upcoming Conferences/
    assert_select ".card-body", text: /Upcoming Con/
  end

  # Volunteer Dashboard Tests
  test "volunteer sees my stats card" do
    user = User.create!(
      email: "volunteer@example.com",
      password: "password123",
      password_confirmation: "password123"
    )

    sign_in user
    get root_url

    assert_response :success
    assert_select "h2", text: /My Volunteering/
    assert_select ".card-header", text: /My Stats/
  end

  test "volunteer sees my upcoming shifts card" do
    user = User.create!(
      email: "volunteer@example.com",
      password: "password123",
      password_confirmation: "password123"
    )

    sign_in user
    get root_url

    assert_response :success
    assert_select ".card-header", text: /My Upcoming Shifts/
  end

  test "volunteer sees my qualifications card" do
    user = User.create!(
      email: "volunteer@example.com",
      password: "password123",
      password_confirmation: "password123"
    )

    sign_in user
    get root_url

    assert_response :success
    assert_select ".card-header", text: /My Qualifications/
  end

  test "unauthenticated user sees sign in prompt" do
    get root_url

    assert_response :success
    assert_select ".alert-info", text: /Sign in/
  end

  # Volunteering For Card Tests
  test "volunteer sees Volunteering For card" do
    user = User.create!(
      email: "volunteer@example.com",
      password: "password123",
      password_confirmation: "password123"
    )

    sign_in user
    get root_url

    assert_response :success
    assert_select ".card-header", text: /Volunteering For/
  end

  test "Volunteering For card shows conferences user has signed up for" do
    user = User.create!(
      email: "volunteer@example.com",
      password: "password123",
      password_confirmation: "password123"
    )
    conference = Conference.create!(
      name: "Test Conference",
      village: @village,
      start_date: Date.tomorrow,
      end_date: Date.tomorrow + 3.days,
      conference_hours_start: "09:00",
      conference_hours_end: "17:00"
    )
    program = Program.create!(name: "Test Program", village: @village)
    conference_program = ConferenceProgram.create!(
      conference: conference,
      program: program
    )
    timeslot = Timeslot.create!(
      conference_program: conference_program,
      start_time: Date.tomorrow.to_datetime + 9.hours,
      max_volunteers: 5
    )
    VolunteerSignup.create!(user: user, timeslot: timeslot)

    sign_in user
    get root_url

    assert_response :success
    assert_select ".card-header", text: /Volunteering For/
    assert_select ".list-group-item", text: /Test Conference/
  end

  test "Volunteering For card shows shift count for each conference" do
    user = User.create!(
      email: "volunteer@example.com",
      password: "password123",
      password_confirmation: "password123"
    )
    conference = Conference.create!(
      name: "Test Conference",
      village: @village,
      start_date: Date.tomorrow,
      end_date: Date.tomorrow + 3.days,
      conference_hours_start: "09:00",
      conference_hours_end: "17:00"
    )
    program = Program.create!(name: "Test Program", village: @village)
    conference_program = ConferenceProgram.create!(
      conference: conference,
      program: program
    )
    # Create 3 signups
    3.times do |i|
      timeslot = Timeslot.create!(
        conference_program: conference_program,
        start_time: Date.tomorrow.to_datetime + (9 + i).hours,
        max_volunteers: 5
      )
      VolunteerSignup.create!(user: user, timeslot: timeslot)
    end

    sign_in user
    get root_url

    assert_response :success
    assert_select ".badge.bg-success", text: /3 shifts/
  end

  test "Volunteering For card shows empty state when no signups" do
    user = User.create!(
      email: "volunteer@example.com",
      password: "password123",
      password_confirmation: "password123"
    )

    sign_in user
    get root_url

    assert_response :success
    assert_select ".card-header", text: /Volunteering For/
    assert_select ".card-body", text: /haven't signed up for any conferences/
  end

  test "Volunteering For card only shows future conferences" do
    user = User.create!(
      email: "volunteer@example.com",
      password: "password123",
      password_confirmation: "password123"
    )
    # Past conference
    past_conference = Conference.create!(
      name: "Past Conference",
      village: @village,
      start_date: 10.days.ago.to_date,
      end_date: 5.days.ago.to_date,
      conference_hours_start: "09:00",
      conference_hours_end: "17:00"
    )
    # Future conference
    future_conference = Conference.create!(
      name: "Future Conference",
      village: @village,
      start_date: Date.tomorrow,
      end_date: Date.tomorrow + 3.days,
      conference_hours_start: "09:00",
      conference_hours_end: "17:00"
    )
    program = Program.create!(name: "Test Program", village: @village)

    # Sign up for past conference
    past_cp = ConferenceProgram.create!(conference: past_conference, program: program)
    past_timeslot = Timeslot.create!(
      conference_program: past_cp,
      start_time: 7.days.ago.to_datetime + 9.hours,
      max_volunteers: 5
    )
    VolunteerSignup.create!(user: user, timeslot: past_timeslot)

    # Sign up for future conference
    future_cp = ConferenceProgram.create!(conference: future_conference, program: program)
    future_timeslot = Timeslot.create!(
      conference_program: future_cp,
      start_time: Date.tomorrow.to_datetime + 9.hours,
      max_volunteers: 5
    )
    VolunteerSignup.create!(user: user, timeslot: future_timeslot)

    sign_in user
    get root_url

    assert_response :success
    assert_select ".card-header", text: /Volunteering For/
    assert_select ".list-group-item", text: /Future Conference/
    assert_select ".list-group-item", text: /Past Conference/, count: 0
  end

  # Open Opportunities Card Tests
  test "volunteer sees Open Opportunities card" do
    user = User.create!(
      email: "volunteer@example.com",
      password: "password123",
      password_confirmation: "password123"
    )

    sign_in user
    get root_url

    assert_response :success
    assert_select ".card-header", text: /Open Opportunities/
  end
end
