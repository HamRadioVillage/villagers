class ShiftReminderJob < ApplicationJob
  queue_as :default

  def perform
    return unless Village.email_enabled?

    # Find all signups needing reminders, grouped by conference
    signups_by_conference = find_signups_needing_reminders

    signups_by_conference.each do |conference, user_signups|
      user_signups.each do |user, signups|
        send_reminder(user, signups, conference)
      end
    end
  end

  private

  def find_signups_needing_reminders
    signups = VolunteerSignup
      .joins(timeslot: { conference_program: :conference })
      .includes(timeslot: { conference_program: [ :conference, :program ] }, user: [])
      .where(reminder_sent_at: nil)
      .where("timeslots.start_time > ?", Time.current)

    # Group by conference, then filter by each conference's reminder window
    signups_by_conference = {}

    signups.each do |signup|
      conference = signup.timeslot.conference_program.conference
      reminder_hours = conference.effective_reminder_hours
      reminder_window_start = Time.current + reminder_hours.hours

      # Only include if within the reminder window
      next unless signup.timeslot.start_time <= reminder_window_start

      signups_by_conference[conference] ||= {}
      signups_by_conference[conference][signup.user] ||= []
      signups_by_conference[conference][signup.user] << signup
    end

    signups_by_conference
  end

  def send_reminder(user, signups, conference)
    VolunteerMailer.shift_reminder(
      user: user,
      signups: signups,
      conference: conference
    ).deliver_now

    # Mark all signups as reminded
    signup_ids = signups.map(&:id)
    VolunteerSignup.where(id: signup_ids).update_all(reminder_sent_at: Time.current)
  end
end
