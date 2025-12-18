class VolunteerMailerPreview < ActionMailer::Preview
  # Preview: http://localhost:3000/rails/mailers/volunteer_mailer/shift_signup_confirmation
  def shift_signup_confirmation
    user = User.first || User.new(email: "preview@example.com", name: "Preview User")
    conference = Conference.first || Conference.new(name: "Preview Conference")
    program = Program.first || Program.new(name: "Preview Program")
    conference_program = ConferenceProgram.new(conference: conference, program: program)

    # Create mock signups for preview
    signups = 3.times.map do |i|
      timeslot = Timeslot.new(
        conference_program: conference_program,
        start_time: Time.current.beginning_of_day + 10.hours + (i * 15).minutes,
        max_volunteers: 5
      )
      VolunteerSignup.new(user: user, timeslot: timeslot)
    end

    VolunteerMailer.shift_signup_confirmation(
      user: user,
      signups: signups,
      conference: conference
    )
  end
end
