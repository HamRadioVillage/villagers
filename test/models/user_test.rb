require "test_helper"

class UserTest < ActiveSupport::TestCase
  setup do
    @village = Village.create!(name: "Test Village", setup_complete: true)
    @user = User.create!(email: "test@example.com", password: "password123", password_confirmation: "password123")
    @program = Program.create!(name: "Test Program", description: "Test", village: @village)
  end

  # Program lead tests
  test "user can have program roles" do
    role = ProgramRole.create!(user: @user, program: @program, role_name: ProgramRole::PROGRAM_LEAD)
    assert_includes @user.program_roles, role
  end

  test "program_lead? returns true when user is a program lead" do
    ProgramRole.create!(user: @user, program: @program, role_name: ProgramRole::PROGRAM_LEAD)
    assert @user.program_lead?(@program)
  end

  test "program_lead? returns false when user is not a program lead" do
    assert_not @user.program_lead?(@program)
  end

  test "can_manage_program? returns true for village admin" do
    admin_role = Role.create!(name: Role::VILLAGE_ADMIN)
    UserRole.create!(user: @user, role: admin_role)
    assert @user.can_manage_program?(@program)
  end

  test "can_manage_program? returns true for program lead" do
    ProgramRole.create!(user: @user, program: @program, role_name: ProgramRole::PROGRAM_LEAD)
    assert @user.can_manage_program?(@program)
  end

  test "can_manage_program? returns true for conference lead of conference-specific program" do
    conference = Conference.create!(
      name: "Test Conference",
      village: @village,
      start_date: Date.tomorrow,
      end_date: Date.tomorrow + 3.days
    )
    conference_program = Program.create!(
      name: "Conference Program",
      village: @village,
      conference: conference
    )
    ConferenceRole.create!(user: @user, conference: conference, role_name: ConferenceRole::CONFERENCE_LEAD)
    assert @user.can_manage_program?(conference_program)
  end

  test "can_manage_program? returns false for regular user" do
    assert_not @user.can_manage_program?(@program)
  end

  test "led_programs returns programs where user is a lead" do
    program2 = Program.create!(name: "Another Program", description: "Test", village: @village)
    ProgramRole.create!(user: @user, program: @program, role_name: ProgramRole::PROGRAM_LEAD)

    assert_includes @user.led_programs, @program
    assert_not_includes @user.led_programs, program2
  end

  test "deleting user deletes associated program roles" do
    ProgramRole.create!(user: @user, program: @program, role_name: ProgramRole::PROGRAM_LEAD)

    assert_difference "ProgramRole.count", -1 do
      @user.destroy
    end
  end

  # Qualification method tests
  test "has_qualification? returns true when user has qualification" do
    qualification = Qualification.create!(name: "Test Qual", description: "Test description", village: @village)
    UserQualification.create!(user: @user, qualification: qualification)
    assert @user.has_qualification?(qualification)
  end

  test "has_qualification? returns false when user lacks qualification" do
    qualification = Qualification.create!(name: "Test Qual", description: "Test description", village: @village)
    assert_not @user.has_qualification?(qualification)
  end

  test "has_qualification_for_program? returns true when all qualifications met" do
    qual1 = Qualification.create!(name: "Qual 1", description: "Description 1", village: @village)
    qual2 = Qualification.create!(name: "Qual 2", description: "Description 2", village: @village)
    ProgramQualification.create!(program: @program, qualification: qual1)
    ProgramQualification.create!(program: @program, qualification: qual2)
    UserQualification.create!(user: @user, qualification: qual1)
    UserQualification.create!(user: @user, qualification: qual2)

    assert @user.has_qualification_for_program?(@program)
  end

  test "has_qualification_for_program? returns false when missing qualification" do
    qual1 = Qualification.create!(name: "Qual 1", description: "Description 1", village: @village)
    qual2 = Qualification.create!(name: "Qual 2", description: "Description 2", village: @village)
    ProgramQualification.create!(program: @program, qualification: qual1)
    ProgramQualification.create!(program: @program, qualification: qual2)
    UserQualification.create!(user: @user, qualification: qual1)
    # Missing qual2

    assert_not @user.has_qualification_for_program?(@program)
  end

  test "has_qualification_for_program? returns true when program has no qualifications" do
    assert @user.has_qualification_for_program?(@program)
  end

  test "has_conference_qualification? returns true when granted" do
    conference = Conference.create!(
      name: "Test Conference",
      village: @village,
      start_date: Date.tomorrow,
      end_date: Date.tomorrow + 3.days
    )
    conference_qual = ConferenceQualification.create!(
      conference: conference,
      name: "Conference Qual",
      description: "Conference qualification description"
    )
    ConferenceUserQualification.create!(user: @user, conference_qualification: conference_qual)

    assert @user.has_conference_qualification?(conference_qual)
  end

  test "has_conference_qualification? returns false when not granted" do
    conference = Conference.create!(
      name: "Test Conference",
      village: @village,
      start_date: Date.tomorrow,
      end_date: Date.tomorrow + 3.days
    )
    conference_qual = ConferenceQualification.create!(
      conference: conference,
      name: "Conference Qual",
      description: "Conference qualification description"
    )

    assert_not @user.has_conference_qualification?(conference_qual)
  end

  test "qualification_removed_for_conference? returns true when removed" do
    conference = Conference.create!(
      name: "Test Conference",
      village: @village,
      start_date: Date.tomorrow,
      end_date: Date.tomorrow + 3.days
    )
    qualification = Qualification.create!(name: "Test Qual", description: "Test description", village: @village)
    QualificationRemoval.create!(user: @user, qualification: qualification, conference: conference)

    assert @user.qualification_removed_for_conference?(qualification, conference)
  end

  test "qualification_removed_for_conference? returns false when not removed" do
    conference = Conference.create!(
      name: "Test Conference",
      village: @village,
      start_date: Date.tomorrow,
      end_date: Date.tomorrow + 3.days
    )
    qualification = Qualification.create!(name: "Test Qual", description: "Test description", village: @village)

    assert_not @user.qualification_removed_for_conference?(qualification, conference)
  end

  test "effective_qualification_for_conference? returns true when has qual and not removed" do
    conference = Conference.create!(
      name: "Test Conference",
      village: @village,
      start_date: Date.tomorrow,
      end_date: Date.tomorrow + 3.days
    )
    qualification = Qualification.create!(name: "Test Qual", description: "Test description", village: @village)
    UserQualification.create!(user: @user, qualification: qualification)

    assert @user.effective_qualification_for_conference?(qualification, conference)
  end

  test "effective_qualification_for_conference? returns false when qual is removed" do
    conference = Conference.create!(
      name: "Test Conference",
      village: @village,
      start_date: Date.tomorrow,
      end_date: Date.tomorrow + 3.days
    )
    qualification = Qualification.create!(name: "Test Qual", description: "Test description", village: @village)
    UserQualification.create!(user: @user, qualification: qualification)
    QualificationRemoval.create!(user: @user, qualification: qualification, conference: conference)

    assert_not @user.effective_qualification_for_conference?(qualification, conference)
  end

  test "effective_qualification_for_conference? returns false when user lacks qual" do
    conference = Conference.create!(
      name: "Test Conference",
      village: @village,
      start_date: Date.tomorrow,
      end_date: Date.tomorrow + 3.days
    )
    qualification = Qualification.create!(name: "Test Qual", description: "Test description", village: @village)

    assert_not @user.effective_qualification_for_conference?(qualification, conference)
  end

  # Volunteer statistics method tests
  test "total_shifts returns volunteer signup count" do
    conference = Conference.create!(
      name: "Test Conference",
      village: @village,
      start_date: Date.tomorrow,
      end_date: Date.tomorrow + 3.days,
      conference_hours_start: "09:00",
      conference_hours_end: "17:00"
    )
    conference_program = ConferenceProgram.create!(conference: conference, program: @program)
    timeslot1 = Timeslot.create!(
      conference_program: conference_program,
      start_time: Date.tomorrow.to_datetime + 9.hours,
      max_volunteers: 2
    )
    timeslot2 = Timeslot.create!(
      conference_program: conference_program,
      start_time: Date.tomorrow.to_datetime + 10.hours,
      max_volunteers: 2
    )
    VolunteerSignup.create!(user: @user, timeslot: timeslot1)
    VolunteerSignup.create!(user: @user, timeslot: timeslot2)

    assert_equal 2, @user.total_shifts
  end

  test "total_volunteer_hours calculates correctly" do
    conference = Conference.create!(
      name: "Test Conference",
      village: @village,
      start_date: Date.tomorrow,
      end_date: Date.tomorrow + 3.days,
      conference_hours_start: "09:00",
      conference_hours_end: "17:00"
    )
    conference_program = ConferenceProgram.create!(conference: conference, program: @program)
    timeslot1 = Timeslot.create!(
      conference_program: conference_program,
      start_time: Date.tomorrow.to_datetime + 9.hours,
      max_volunteers: 2
    )
    timeslot2 = Timeslot.create!(
      conference_program: conference_program,
      start_time: Date.tomorrow.to_datetime + 10.hours,
      max_volunteers: 2
    )
    VolunteerSignup.create!(user: @user, timeslot: timeslot1)
    VolunteerSignup.create!(user: @user, timeslot: timeslot2)

    # 2 shifts * 0.25 hours each = 0.5 hours
    assert_equal 0.5, @user.total_volunteer_hours
  end

  test "conferences_participated returns distinct conferences" do
    conference1 = Conference.create!(
      name: "Conference 1",
      village: @village,
      start_date: Date.tomorrow,
      end_date: Date.tomorrow + 3.days,
      conference_hours_start: "09:00",
      conference_hours_end: "17:00"
    )
    conference2 = Conference.create!(
      name: "Conference 2",
      village: @village,
      start_date: Date.tomorrow + 10.days,
      end_date: Date.tomorrow + 13.days,
      conference_hours_start: "09:00",
      conference_hours_end: "17:00"
    )
    cp1 = ConferenceProgram.create!(conference: conference1, program: @program)
    cp2 = ConferenceProgram.create!(conference: conference2, program: @program)
    timeslot1 = Timeslot.create!(conference_program: cp1, start_time: Date.tomorrow.to_datetime + 9.hours, max_volunteers: 2)
    timeslot2 = Timeslot.create!(conference_program: cp1, start_time: Date.tomorrow.to_datetime + 10.hours, max_volunteers: 2)
    timeslot3 = Timeslot.create!(conference_program: cp2, start_time: (Date.tomorrow + 10.days).to_datetime + 9.hours, max_volunteers: 2)
    VolunteerSignup.create!(user: @user, timeslot: timeslot1)
    VolunteerSignup.create!(user: @user, timeslot: timeslot2)
    VolunteerSignup.create!(user: @user, timeslot: timeslot3)

    participated = @user.conferences_participated
    assert_equal 2, participated.count
    assert_includes participated, conference1
    assert_includes participated, conference2
  end

  test "conferences_participated_count returns count" do
    conference = Conference.create!(
      name: "Test Conference",
      village: @village,
      start_date: Date.tomorrow,
      end_date: Date.tomorrow + 3.days,
      conference_hours_start: "09:00",
      conference_hours_end: "17:00"
    )
    cp = ConferenceProgram.create!(conference: conference, program: @program)
    timeslot = Timeslot.create!(conference_program: cp, start_time: Date.tomorrow.to_datetime + 9.hours, max_volunteers: 2)
    VolunteerSignup.create!(user: @user, timeslot: timeslot)

    assert_equal 1, @user.conferences_participated_count
  end

  test "shifts_for_conference returns count for specific conference" do
    conference1 = Conference.create!(
      name: "Conference 1",
      village: @village,
      start_date: Date.tomorrow,
      end_date: Date.tomorrow + 3.days,
      conference_hours_start: "09:00",
      conference_hours_end: "17:00"
    )
    conference2 = Conference.create!(
      name: "Conference 2",
      village: @village,
      start_date: Date.tomorrow + 10.days,
      end_date: Date.tomorrow + 13.days,
      conference_hours_start: "09:00",
      conference_hours_end: "17:00"
    )
    cp1 = ConferenceProgram.create!(conference: conference1, program: @program)
    cp2 = ConferenceProgram.create!(conference: conference2, program: @program)
    timeslot1 = Timeslot.create!(conference_program: cp1, start_time: Date.tomorrow.to_datetime + 9.hours, max_volunteers: 2)
    timeslot2 = Timeslot.create!(conference_program: cp1, start_time: Date.tomorrow.to_datetime + 10.hours, max_volunteers: 2)
    timeslot3 = Timeslot.create!(conference_program: cp2, start_time: (Date.tomorrow + 10.days).to_datetime + 9.hours, max_volunteers: 2)
    VolunteerSignup.create!(user: @user, timeslot: timeslot1)
    VolunteerSignup.create!(user: @user, timeslot: timeslot2)
    VolunteerSignup.create!(user: @user, timeslot: timeslot3)

    assert_equal 2, @user.shifts_for_conference(conference1)
    assert_equal 1, @user.shifts_for_conference(conference2)
  end

  test "hours_for_conference calculates correctly" do
    conference = Conference.create!(
      name: "Test Conference",
      village: @village,
      start_date: Date.tomorrow,
      end_date: Date.tomorrow + 3.days,
      conference_hours_start: "09:00",
      conference_hours_end: "17:00"
    )
    cp = ConferenceProgram.create!(conference: conference, program: @program)
    timeslot1 = Timeslot.create!(conference_program: cp, start_time: Date.tomorrow.to_datetime + 9.hours, max_volunteers: 2)
    timeslot2 = Timeslot.create!(conference_program: cp, start_time: Date.tomorrow.to_datetime + 10.hours, max_volunteers: 2)
    VolunteerSignup.create!(user: @user, timeslot: timeslot1)
    VolunteerSignup.create!(user: @user, timeslot: timeslot2)

    # 2 shifts * 0.25 hours = 0.5 hours
    assert_equal 0.5, @user.hours_for_conference(conference)
  end

  test "volunteer_signups_for_conference returns signups" do
    conference = Conference.create!(
      name: "Test Conference",
      village: @village,
      start_date: Date.tomorrow,
      end_date: Date.tomorrow + 3.days,
      conference_hours_start: "09:00",
      conference_hours_end: "17:00"
    )
    cp = ConferenceProgram.create!(conference: conference, program: @program)
    timeslot = Timeslot.create!(conference_program: cp, start_time: Date.tomorrow.to_datetime + 9.hours, max_volunteers: 2)
    signup = VolunteerSignup.create!(user: @user, timeslot: timeslot)

    signups = @user.volunteer_signups_for_conference(conference)
    assert_equal 1, signups.count
    assert_includes signups, signup
  end

  test "top_volunteers class method returns ordered list" do
    user2 = User.create!(email: "user2@example.com", password: "password123", password_confirmation: "password123")
    conference = Conference.create!(
      name: "Test Conference",
      village: @village,
      start_date: Date.tomorrow,
      end_date: Date.tomorrow + 3.days,
      conference_hours_start: "09:00",
      conference_hours_end: "17:00"
    )
    cp = ConferenceProgram.create!(conference: conference, program: @program)
    timeslot1 = Timeslot.create!(conference_program: cp, start_time: Date.tomorrow.to_datetime + 9.hours, max_volunteers: 5)
    timeslot2 = Timeslot.create!(conference_program: cp, start_time: Date.tomorrow.to_datetime + 10.hours, max_volunteers: 5)
    # @user has 2 signups
    VolunteerSignup.create!(user: @user, timeslot: timeslot1)
    VolunteerSignup.create!(user: @user, timeslot: timeslot2)
    # user2 has 1 signup
    VolunteerSignup.create!(user: user2, timeslot: timeslot1)

    top = User.top_volunteers(2)
    assert_equal 2, top.to_a.size  # Use to_a.size to avoid COUNT SQL conflict
    assert_equal @user.id, top.first.id  # @user should be first with more signups
  end

  test "top_volunteers_for_conference filters by conference" do
    user2 = User.create!(email: "user2@example.com", password: "password123", password_confirmation: "password123")
    conference1 = Conference.create!(
      name: "Conference 1",
      village: @village,
      start_date: Date.tomorrow,
      end_date: Date.tomorrow + 3.days,
      conference_hours_start: "09:00",
      conference_hours_end: "17:00"
    )
    conference2 = Conference.create!(
      name: "Conference 2",
      village: @village,
      start_date: Date.tomorrow + 10.days,
      end_date: Date.tomorrow + 13.days,
      conference_hours_start: "09:00",
      conference_hours_end: "17:00"
    )
    cp1 = ConferenceProgram.create!(conference: conference1, program: @program)
    cp2 = ConferenceProgram.create!(conference: conference2, program: @program)
    timeslot1 = Timeslot.create!(conference_program: cp1, start_time: Date.tomorrow.to_datetime + 9.hours, max_volunteers: 5)
    timeslot2 = Timeslot.create!(conference_program: cp2, start_time: (Date.tomorrow + 10.days).to_datetime + 9.hours, max_volunteers: 5)

    # @user has signups in both conferences
    VolunteerSignup.create!(user: @user, timeslot: timeslot1)
    VolunteerSignup.create!(user: @user, timeslot: timeslot2)
    # user2 only has signup in conference2
    VolunteerSignup.create!(user: user2, timeslot: timeslot2)

    top_for_conf1 = User.top_volunteers_for_conference(conference1, 10)
    assert_equal 1, top_for_conf1.to_a.size  # Use to_a.size to avoid COUNT SQL conflict
    assert_equal @user.id, top_for_conf1.first.id
  end
end
