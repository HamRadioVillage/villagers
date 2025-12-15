require "test_helper"

class VolunteerSignupsControllerTest < ActionDispatch::IntegrationTest
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
    @volunteer2 = User.create!(
      email: "volunteer2@example.com",
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

    @program = Program.create!(
      name: "Test Program",
      village: @village
    )

    @conference_program = ConferenceProgram.create!(
      conference: @conference,
      program: @program
    )

    @timeslot = Timeslot.create!(
      conference_program: @conference_program,
      start_time: Date.tomorrow.to_datetime + 9.hours,
      max_volunteers: 2
    )

    @timeslot2 = Timeslot.create!(
      conference_program: @conference_program,
      start_time: Date.tomorrow.to_datetime + 10.hours,
      max_volunteers: 2
    )
  end

  # Index tests
  test "should get index as authenticated user" do
    sign_in @volunteer
    get conference_volunteer_signups_url(@conference)
    assert_response :success
  end

  test "should redirect index to login when not authenticated" do
    get conference_volunteer_signups_url(@conference)
    assert_redirected_to new_user_session_path
  end

  test "index shows user's signups for this conference" do
    VolunteerSignup.create!(user: @volunteer, timeslot: @timeslot)
    sign_in @volunteer
    get conference_volunteer_signups_url(@conference)
    assert_response :success
  end

  # Create tests
  test "should create signup for available timeslot" do
    sign_in @volunteer
    assert_difference("VolunteerSignup.count") do
      post conference_volunteer_signups_url(@conference), params: {
        timeslot_id: @timeslot.id
      }
    end
    assert_redirected_to conference_volunteer_signups_path(@conference)
  end

  test "should not create duplicate signup" do
    VolunteerSignup.create!(user: @volunteer, timeslot: @timeslot)
    sign_in @volunteer
    assert_no_difference("VolunteerSignup.count") do
      post conference_volunteer_signups_url(@conference), params: {
        timeslot_id: @timeslot.id
      }
    end
    assert_redirected_to conference_volunteer_signups_path(@conference)
  end

  test "should not create signup when timeslot is full" do
    # Fill the timeslot
    @timeslot.update!(max_volunteers: 1)
    VolunteerSignup.create!(user: @volunteer2, timeslot: @timeslot)

    sign_in @volunteer
    assert_no_difference("VolunteerSignup.count") do
      post conference_volunteer_signups_url(@conference), params: {
        timeslot_id: @timeslot.id
      }
    end
    assert_redirected_to conference_volunteer_signups_path(@conference)
  end

  test "should redirect create to login when not authenticated" do
    assert_no_difference("VolunteerSignup.count") do
      post conference_volunteer_signups_url(@conference), params: {
        timeslot_id: @timeslot.id
      }
    end
    assert_redirected_to new_user_session_path
  end

  # Destroy tests
  test "should destroy own signup" do
    signup = VolunteerSignup.create!(user: @volunteer, timeslot: @timeslot)
    sign_in @volunteer
    assert_difference("VolunteerSignup.count", -1) do
      delete conference_volunteer_signup_url(@conference, signup)
    end
    assert_redirected_to conference_volunteer_signups_path(@conference)
  end

  test "should not destroy other user's signup" do
    signup = VolunteerSignup.create!(user: @volunteer2, timeslot: @timeslot)
    sign_in @volunteer
    # The controller scopes to current_user.volunteer_signups, so the signup won't be found
    # and the request will fail (either with 404 or ActiveRecord::RecordNotFound)
    assert_no_difference("VolunteerSignup.count") do
      begin
        delete conference_volunteer_signup_url(@conference, signup)
      rescue ActiveRecord::RecordNotFound
        # Expected behavior - signup not found in user's signups scope
      end
    end
  end

  test "should redirect destroy to login when not authenticated" do
    signup = VolunteerSignup.create!(user: @volunteer, timeslot: @timeslot)
    assert_no_difference("VolunteerSignup.count") do
      delete conference_volunteer_signup_url(@conference, signup)
    end
    assert_redirected_to new_user_session_path
  end

  test "multiple signups for different timeslots are allowed" do
    sign_in @volunteer
    assert_difference("VolunteerSignup.count", 2) do
      post conference_volunteer_signups_url(@conference), params: {
        timeslot_id: @timeslot.id
      }
      post conference_volunteer_signups_url(@conference), params: {
        timeslot_id: @timeslot2.id
      }
    end
  end
end
