class NotificationService
  class << self
    def notify_shift_signup(user:, timeslot:)
      notify_shift_signups(user: user, signups: [ timeslot.volunteer_signups.find_by(user: user) ].compact)
    end

    def notify_shift_signups(user:, signups:)
      return if signups.empty?

      first_signup = signups.first
      conference = first_signup.timeslot.conference_program.conference
      program_name = first_signup.timeslot.conference_program.program.name

      if signups.size == 1
        start_time = first_signup.timeslot.start_time.strftime("%B %d, %Y at %l:%M %p")
        body = "You've signed up for a #{program_name} shift at #{conference.name} on #{start_time}."
      else
        total_minutes = signups.size * 15
        hours = total_minutes / 60
        mins = total_minutes % 60
        duration = hours > 0 ? "#{hours} hour#{'s' if hours != 1}" : ""
        duration += " #{mins} minute#{'s' if mins != 1}" if mins > 0
        body = "You've signed up for #{signups.size} shifts (#{duration.strip}) at #{conference.name}."
      end

      # Create in-app notification
      if user.should_notify_in_app?
        user.notifications.create!(
          title: "Shift Signup Confirmed",
          body: body,
          notification_type: Notification::SHIFT_SIGNUP
        )
      end

      # Send detailed email confirmation
      if user.should_notify_by_email?
        VolunteerMailer.shift_signup_confirmation(
          user: user,
          signups: signups,
          conference: conference
        ).deliver_later
      end
    end

    def notify_shift_cancelled(user:, timeslot:)
      program_name = timeslot.conference_program.program.name
      conference_name = timeslot.conference_program.conference.name
      start_time = timeslot.start_time.strftime("%B %d, %Y at %l:%M %p")

      send_notification(
        user: user,
        title: "Shift Cancelled",
        body: "Your #{program_name} shift at #{conference_name} on #{start_time} has been cancelled.",
        notification_type: Notification::SHIFT_CANCELLED
      )
    end

    def notify_shift_reminder(user:, timeslot:, minutes_before: 60)
      program_name = timeslot.conference_program.program.name
      conference_name = timeslot.conference_program.conference.name
      start_time = timeslot.start_time.strftime("%l:%M %p")

      send_notification(
        user: user,
        title: "Shift Reminder",
        body: "Your #{program_name} shift at #{conference_name} starts in #{minutes_before} minutes (#{start_time}).",
        notification_type: Notification::SHIFT_REMINDER
      )
    end

    def notify_admin_new_signup(admin:, volunteer:, timeslot:)
      program_name = timeslot.conference_program.program.name
      start_time = timeslot.start_time.strftime("%B %d at %l:%M %p")

      send_notification(
        user: admin,
        title: "New Volunteer Signup",
        body: "#{volunteer.email} signed up for #{program_name} on #{start_time}.",
        notification_type: Notification::ADMIN_ALERT
      )
    end

    def send_system_notification(user:, title:, body:)
      send_notification(
        user: user,
        title: title,
        body: body,
        notification_type: Notification::SYSTEM
      )
    end

    private

    def send_notification(user:, title:, body:, notification_type:)
      # Create in-app notification if user has it enabled
      if user.should_notify_in_app?
        user.notifications.create!(
          title: title,
          body: body,
          notification_type: notification_type
        )
      end

      # Send email notification if user has it enabled and email is configured
      if user.should_notify_by_email?
        NotificationMailer.notification_email(
          user: user,
          title: title,
          body: body,
          notification_type: notification_type
        ).deliver_later
      end
    end
  end
end
