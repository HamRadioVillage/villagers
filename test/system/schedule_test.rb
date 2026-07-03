require "application_system_test_case"

class ScheduleTest < ApplicationSystemTestCase
  setup do
    @village = Village.create!(name: "Test Village", setup_complete: true)
    @conference = Conference.create!(
      name: "Test Conference",
      city: "Test City", state: "NV", country: "US",
      start_date: Date.today,
      end_date: Date.today + 1.day,
      conference_hours_start: Time.zone.parse("2000-01-01 09:00"),
      conference_hours_end: Time.zone.parse("2000-01-01 12:00"),
      village: @village
    )
    @program = Program.create!(
      name: "Test Program",
      description: "A test program",
      village: @village
    )
    @conference_program = ConferenceProgram.create!(
      conference: @conference,
      program: @program,
      day_schedules: {
        "0" => { "enabled" => true, "start" => "09:00", "end" => "10:00" }
      }
    )
    @timeslot = @conference_program.timeslots.first

    @volunteer = User.create!(
      email: "volunteer@example.com",
      password: "password123",
      password_confirmation: "password123"
    )

    @admin = User.create!(
      email: "admin@example.com",
      password: "password123",
      password_confirmation: "password123"
    )
    village_admin_role = Role.find_or_create_by!(name: Role::VILLAGE_ADMIN)
    UserRole.find_or_create_by!(user: @admin, role: village_admin_role)
  end

  teardown do
    # Window size persists across tests in the same browser; reset so later
    # desktop-oriented tests aren't affected by the mobile-view tests.
    page.driver.browser.manage.window.resize_to(1400, 1400)
  end

  def login_as(user)
    visit new_user_session_path
    fill_in "Email", with: user.email
    fill_in "Password", with: "password123"
    find('input[type="submit"][value="Log in"]').click
    assert_text "Logout"
  end

  def resize_to_mobile
    page.driver.browser.manage.window.resize_to(390, 844)
  end

  # Creates a second program running at the same time as @conference_program,
  # so a collapsed time slot offers more than one shift type.
  def add_second_program(name: "Second Program")
    program = Program.create!(name: name, description: "Another program", village: @village)
    ConferenceProgram.create!(
      conference: @conference,
      program: program,
      day_schedules: { "0" => { "enabled" => true, "start" => "09:00", "end" => "10:00" } }
    )
    program
  end

  test "schedule view shows vertical timeline with time slots" do
    login_as @volunteer
    visit conference_schedule_path(@conference)

    assert_text "Schedule"
    assert_text "9:00 AM"
    assert_text @program.name
  end

  test "volunteer sees their own shifts highlighted" do
    VolunteerSignup.create!(user: @volunteer, timeslot: @timeslot)

    login_as @volunteer
    visit conference_schedule_path(@conference)

    # Should show the volunteer's signup (class is now on cell, not slot)
    assert_selector ".schedule-cell.user-signed-up"
  end

  test "volunteer does not see other users names" do
    other_user = User.create!(
      email: "other@example.com",
      password: "password123",
      password_confirmation: "password123"
    )
    VolunteerSignup.create!(user: other_user, timeslot: @timeslot)

    login_as @volunteer
    visit conference_schedule_path(@conference)

    # Volunteer should not see other user's email
    assert_no_text "other@example.com"
  end

  test "admin sees all volunteers across all programs" do
    VolunteerSignup.create!(user: @volunteer, timeslot: @timeslot)

    login_as @admin
    visit conference_schedule_path(@conference)

    # Admin should see volunteer's email
    assert_text "volunteer@example.com"
  end

  test "schedule is accessible from conference show page" do
    login_as @volunteer
    visit conference_path(@conference)

    click_link "View Schedule", match: :first

    assert_selector "h1", text: "#{@conference.name} - Schedule"
  end

  test "schedule shows all conference days" do
    login_as @volunteer
    visit conference_schedule_path(@conference)

    # Should show both days
    assert_text Date.today.strftime("%A, %B %d")
    assert_text (Date.today + 1.day).strftime("%A, %B %d")
  end

  test "long qualification-required pill wraps within the program column" do
    qualification = Qualification.create!(
      village: @village,
      name: "Amateur Radio Extra Class License with Vanity Callsign Endorsement",
      description: "A qualification with a deliberately long name"
    )
    @program.qualifications << qualification

    login_as @volunteer
    visit conference_schedule_path(@conference)

    pill = find(".qualification-pill", match: :first)
    assert_match(/qualification required/, pill.text)

    # The pill must allow its text to wrap and long words to break so it
    # stays within the fixed-width program column instead of overflowing.
    assert_equal "normal", pill.native.css_value("white-space")
    assert_equal "break-word", pill.native.css_value("word-break")

    # The rendered pill should not be wider than its containing program column.
    column = find(".program-column", match: :first)
    assert pill.native.size.width <= column.native.size.width,
           "Qualification pill (#{pill.native.size.width}px) overflowed the program column (#{column.native.size.width}px)"
  end

  test "hides program column on days with no timeslots" do
    login_as @volunteer
    visit conference_schedule_path(@conference)

    # Program is enabled only on day 0, so day 1's card shows the program header
    # while day 2's card omits it and shows the empty-day fallback.
    day_one = find(".card", text: Date.today.strftime("%A, %B %d"))
    assert day_one.has_selector?("th.program-column", text: @program.name)

    day_two = find(".card", text: (Date.today + 1.day).strftime("%A, %B %d"))
    assert_not day_two.has_selector?("th.program-column", text: @program.name)
    assert day_two.has_text?("No programs scheduled")
  end

  test "schedule header row is sticky" do
    login_as @volunteer
    visit conference_schedule_path(@conference)

    # The program-name header cells should use position: sticky so they stay
    # pinned to the top of the viewport while scrolling a day's table.
    position = page.evaluate_script(
      "getComputedStyle(document.querySelector('.schedule-table thead th')).position"
    )
    assert_equal "sticky", position

    top = page.evaluate_script(
      "getComputedStyle(document.querySelector('.schedule-table thead th')).top"
    )
    assert_equal "0px", top
  end

  test "schedule has signup buttons with modal trigger" do
    login_as @volunteer
    visit conference_schedule_path(@conference)

    # Verify Sign Up buttons exist with the correct data-action for modal
    assert_selector "button[data-action='shift-signup#openModal']", text: "Sign Up"

    # Verify the modal markup exists on the page
    assert_selector "#shiftSignupModal", visible: :hidden
    assert_selector "#shiftDuration", visible: :hidden
  end

  # --- Collapsed mobile view (issue #187) ---

  test "mobile shows the collapsed view and hides the wide table" do
    login_as @volunteer
    resize_to_mobile
    visit conference_schedule_path(@conference)

    # Collapsed single-column view is visible; the wide table is hidden.
    assert_selector ".schedule-collapsed", visible: true
    assert_no_selector ".schedule-table", visible: true
    assert_selector ".schedule-collapsed button", text: "Sign Up", visible: true
  end

  test "mobile sign up lets you pick the shift type then a duration" do
    second = add_second_program

    login_as @volunteer
    resize_to_mobile
    visit conference_schedule_path(@conference)

    assert_selector "[data-shift-signup-ready]" # wait for Stimulus to connect
    find("li.collapsed-slot", text: "9:00 AM").click_button("Sign Up")

    # Step 1: choose which shift type
    within "[data-shift-signup-target='programStep']" do
      assert_text "Which shift type?"
      assert_button @program.name
      assert_button second.name
      click_button second.name
    end

    # Step 2: duration selection for the chosen program
    assert_selector "#shiftDuration", visible: true
    assert_text "Total commitment"

    within ".modal-footer" do
      find("[data-shift-signup-target='submitBtn']").click
    end

    # Lands on "My Shifts" with the shift for the program that was picked.
    assert_text "Your Signed Up Shifts"
    assert_text second.name
  end

  test "mobile sign up skips the picker when only one shift type is available" do
    login_as @volunteer
    resize_to_mobile
    visit conference_schedule_path(@conference)

    assert_selector "[data-shift-signup-ready]" # wait for Stimulus to connect
    find("li.collapsed-slot", text: "9:00 AM").click_button("Sign Up")

    # Only one program at this time -> go straight to duration, no picker step
    assert_selector "#shiftDuration", visible: true
    assert_no_text "Which shift type?"
  end

  # --- Day jump navigation (issue #187) ---

  test "day jump nav shows a button per day for a multi-day conference" do
    login_as @volunteer
    visit conference_schedule_path(@conference)

    assert_selector "nav.schedule-day-nav", visible: true
    within "nav.schedule-day-nav" do
      # setup conference spans 2 days (today .. today + 1)
      assert_selector "a", count: 2
    end
  end

  test "clicking a day jump button navigates to that day's anchor" do
    login_as @volunteer
    visit conference_schedule_path(@conference)

    within "nav.schedule-day-nav" do
      all("a")[1].click
    end

    assert_equal "#schedule-day-1", page.evaluate_script("window.location.hash")
  end

  test "mobile view lets a volunteer cancel a shift they signed up for" do
    VolunteerSignup.create!(user: @volunteer, timeslot: @timeslot)

    login_as @volunteer
    resize_to_mobile
    visit conference_schedule_path(@conference)

    within find("li.collapsed-slot", text: "9:00 AM") do
      assert_text "You're signed up"
      assert_link "Cancel"
    end
  end
end
