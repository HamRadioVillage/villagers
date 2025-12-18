require "test_helper"

class VolunteerMailerTest < ActionMailer::TestCase
  setup do
    @village = Village.create!(name: "Test Village", setup_complete: true, email_enabled: true, mailgun_api_key: "test-key", mailgun_domain: "test.mailgun.org")
    @user = User.create!(
      email: "volunteer@example.com",
      password: "password123",
      password_confirmation: "password123",
      name: "Test Volunteer"
    )
    @conference = Conference.create!(
      village: @village,
      name: "Test Conference",
      start_date: Date.tomorrow,
      end_date: Date.tomorrow + 2.days,
      conference_hours_start: "09:00",
      conference_hours_end: "17:00"
    )
    @program = Program.create!(name: "Test Program", village: @village)
    @conference_program = ConferenceProgram.create!(
      conference: @conference,
      program: @program
    )
    @timeslot = Timeslot.create!(
      conference_program: @conference_program,
      start_time: Date.tomorrow.to_datetime + 9.hours,
      max_volunteers: 5
    )
    @signup = VolunteerSignup.create!(user: @user, timeslot: @timeslot)
  end

  test "shift_signup_confirmation sends to correct recipient" do
    email = VolunteerMailer.shift_signup_confirmation(
      user: @user,
      signups: [ @signup ],
      conference: @conference
    )

    assert_equal [ @user.email ], email.to
  end

  test "shift_signup_confirmation has correct subject" do
    email = VolunteerMailer.shift_signup_confirmation(
      user: @user,
      signups: [ @signup ],
      conference: @conference
    )

    assert_equal "[#{@village.name}] Shift Signup Confirmation - #{@conference.name}", email.subject
  end

  test "shift_signup_confirmation includes program name" do
    email = VolunteerMailer.shift_signup_confirmation(
      user: @user,
      signups: [ @signup ],
      conference: @conference
    )

    assert_match @program.name, email.html_part.body.to_s
    assert_match @program.name, email.text_part.body.to_s
  end

  test "shift_signup_confirmation includes conference name" do
    email = VolunteerMailer.shift_signup_confirmation(
      user: @user,
      signups: [ @signup ],
      conference: @conference
    )

    assert_match @conference.name, email.html_part.body.to_s
    assert_match @conference.name, email.text_part.body.to_s
  end

  test "shift_signup_confirmation includes shift time" do
    email = VolunteerMailer.shift_signup_confirmation(
      user: @user,
      signups: [ @signup ],
      conference: @conference
    )

    # Should include the start time
    assert_match "9:00 AM", email.html_part.body.to_s
    assert_match "9:00 AM", email.text_part.body.to_s
  end

  test "shift_signup_confirmation includes link to My Shifts" do
    email = VolunteerMailer.shift_signup_confirmation(
      user: @user,
      signups: [ @signup ],
      conference: @conference
    )

    # Check that the email contains a link to My Shifts
    assert_match %r{/conferences/\d+/volunteer_signups}, email.html_part.body.to_s
    assert_match %r{/conferences/\d+/volunteer_signups}, email.text_part.body.to_s
  end

  test "shift_signup_confirmation handles multiple signups" do
    timeslot2 = Timeslot.create!(
      conference_program: @conference_program,
      start_time: Date.tomorrow.to_datetime + 9.hours + 15.minutes,
      max_volunteers: 5
    )
    signup2 = VolunteerSignup.create!(user: @user, timeslot: timeslot2)

    email = VolunteerMailer.shift_signup_confirmation(
      user: @user,
      signups: [ @signup, signup2 ],
      conference: @conference
    )

    # Should show duration covering both timeslots (30 minutes)
    assert_match "30 minutes", email.html_part.body.to_s
    assert_match "30 minutes", email.text_part.body.to_s
  end

  test "shift_signup_confirmation shows total duration" do
    email = VolunteerMailer.shift_signup_confirmation(
      user: @user,
      signups: [ @signup ],
      conference: @conference
    )

    # Single 15-minute slot
    assert_match "15 minute", email.html_part.body.to_s
    assert_match "15 minute", email.text_part.body.to_s
  end

  test "shift_signup_confirmation uses user name when available" do
    email = VolunteerMailer.shift_signup_confirmation(
      user: @user,
      signups: [ @signup ],
      conference: @conference
    )

    assert_match @user.name, email.html_part.body.to_s
    assert_match @user.name, email.text_part.body.to_s
  end

  test "shift_signup_confirmation uses email when name not available" do
    @user.update!(name: nil)
    email = VolunteerMailer.shift_signup_confirmation(
      user: @user,
      signups: [ @signup ],
      conference: @conference
    )

    assert_match @user.email, email.html_part.body.to_s
    assert_match @user.email, email.text_part.body.to_s
  end

  # Shift reminder tests
  test "shift_reminder sends to correct recipient" do
    email = VolunteerMailer.shift_reminder(
      user: @user,
      signups: [ @signup ],
      conference: @conference
    )

    assert_equal [ @user.email ], email.to
  end

  test "shift_reminder has correct subject" do
    email = VolunteerMailer.shift_reminder(
      user: @user,
      signups: [ @signup ],
      conference: @conference
    )

    assert_equal "[#{@village.name}] Shift Reminder - #{@conference.name}", email.subject
  end

  test "shift_reminder includes program name" do
    email = VolunteerMailer.shift_reminder(
      user: @user,
      signups: [ @signup ],
      conference: @conference
    )

    assert_match @program.name, email.html_part.body.to_s
    assert_match @program.name, email.text_part.body.to_s
  end

  test "shift_reminder includes shift time" do
    email = VolunteerMailer.shift_reminder(
      user: @user,
      signups: [ @signup ],
      conference: @conference
    )

    assert_match "9:00 AM", email.html_part.body.to_s
    assert_match "9:00 AM", email.text_part.body.to_s
  end

  test "shift_reminder includes link to My Shifts" do
    email = VolunteerMailer.shift_reminder(
      user: @user,
      signups: [ @signup ],
      conference: @conference
    )

    assert_match %r{/conferences/\d+/volunteer_signups}, email.html_part.body.to_s
    assert_match %r{/conferences/\d+/volunteer_signups}, email.text_part.body.to_s
  end

  test "shift_reminder includes location when available" do
    @conference.update!(city: "Las Vegas", state: "NV", country: "US")
    email = VolunteerMailer.shift_reminder(
      user: @user,
      signups: [ @signup ],
      conference: @conference
    )

    assert_match "Las Vegas, NV", email.html_part.body.to_s
    assert_match "Las Vegas, NV", email.text_part.body.to_s
  end
end
