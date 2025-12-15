require "test_helper"

class TimeslotsControllerTest < ActionDispatch::IntegrationTest
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

    @timeslot = Timeslot.create!(
      conference_program: @conference_program,
      start_time: Date.tomorrow.to_datetime + 9.hours,
      max_volunteers: 2
    )
  end

  # Update tests
  test "should update timeslot as village admin" do
    sign_in @village_admin
    patch conference_timeslot_url(@conference, @timeslot), params: {
      timeslot: { max_volunteers: 5 }
    }
    assert_redirected_to conference_schedule_path(@conference)
    @timeslot.reload
    assert_equal 5, @timeslot.max_volunteers
  end

  test "should update timeslot as conference lead" do
    sign_in @conference_lead
    patch conference_timeslot_url(@conference, @timeslot), params: {
      timeslot: { max_volunteers: 3 }
    }
    assert_redirected_to conference_schedule_path(@conference)
    @timeslot.reload
    assert_equal 3, @timeslot.max_volunteers
  end

  test "should not update timeslot as volunteer" do
    sign_in @volunteer
    patch conference_timeslot_url(@conference, @timeslot), params: {
      timeslot: { max_volunteers: 10 }
    }
    assert_redirected_to root_path
    @timeslot.reload
    assert_equal 2, @timeslot.max_volunteers
  end

  test "should redirect to login when updating without authentication" do
    patch conference_timeslot_url(@conference, @timeslot), params: {
      timeslot: { max_volunteers: 5 }
    }
    assert_redirected_to new_user_session_path
  end

  # Add volunteer tests
  test "should add volunteer as conference lead" do
    sign_in @conference_lead
    assert_difference("VolunteerSignup.count") do
      post add_volunteer_conference_timeslot_url(@conference, @timeslot), params: {
        user_id: @volunteer.id
      }
    end
    assert_redirected_to conference_schedule_path(@conference)
    assert @timeslot.users.include?(@volunteer)
  end

  test "should add volunteer as village admin" do
    sign_in @village_admin
    assert_difference("VolunteerSignup.count") do
      post add_volunteer_conference_timeslot_url(@conference, @timeslot), params: {
        user_id: @volunteer.id
      }
    end
    assert_redirected_to conference_schedule_path(@conference)
  end

  test "should not add volunteer as regular volunteer" do
    sign_in @volunteer
    assert_no_difference("VolunteerSignup.count") do
      post add_volunteer_conference_timeslot_url(@conference, @timeslot), params: {
        user_id: @volunteer2.id
      }
    end
    assert_redirected_to root_path
  end

  test "should not add duplicate volunteer" do
    VolunteerSignup.create!(user: @volunteer, timeslot: @timeslot)
    sign_in @conference_lead
    assert_no_difference("VolunteerSignup.count") do
      post add_volunteer_conference_timeslot_url(@conference, @timeslot), params: {
        user_id: @volunteer.id
      }
    end
    assert_redirected_to conference_schedule_path(@conference)
  end

  # Remove volunteer tests
  test "should remove volunteer as conference lead" do
    VolunteerSignup.create!(user: @volunteer, timeslot: @timeslot)
    sign_in @conference_lead
    assert_difference("VolunteerSignup.count", -1) do
      delete remove_volunteer_conference_timeslot_url(@conference, @timeslot), params: {
        user_id: @volunteer.id
      }
    end
    assert_redirected_to conference_schedule_path(@conference)
  end

  test "should remove volunteer as village admin" do
    VolunteerSignup.create!(user: @volunteer, timeslot: @timeslot)
    sign_in @village_admin
    assert_difference("VolunteerSignup.count", -1) do
      delete remove_volunteer_conference_timeslot_url(@conference, @timeslot), params: {
        user_id: @volunteer.id
      }
    end
    assert_redirected_to conference_schedule_path(@conference)
  end

  test "should not remove volunteer as regular volunteer" do
    VolunteerSignup.create!(user: @volunteer, timeslot: @timeslot)
    sign_in @volunteer2
    assert_no_difference("VolunteerSignup.count") do
      delete remove_volunteer_conference_timeslot_url(@conference, @timeslot), params: {
        user_id: @volunteer.id
      }
    end
    assert_redirected_to root_path
  end
end
