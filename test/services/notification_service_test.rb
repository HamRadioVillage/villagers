require "test_helper"

class NotificationServiceTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  setup do
    @village = Village.create!(name: "Test Village", setup_complete: true)
    @user = User.create!(
      email: "test@example.com",
      password: "password123",
      password_confirmation: "password123"
    )
    @admin = User.create!(
      email: "admin@example.com",
      password: "password123",
      password_confirmation: "password123"
    )

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
  end

  test "notify_shift_signup creates in-app notification when enabled" do
    @user.update!(notify_in_app: true, notify_by_email: false)

    assert_difference("Notification.count", 1) do
      NotificationService.notify_shift_signup(user: @user, timeslot: @timeslot)
    end

    notification = @user.notifications.last
    assert_equal "Shift Signup Confirmed", notification.title
    assert_includes notification.body, @program.name
    assert_includes notification.body, @conference.name
    assert_equal Notification::SHIFT_SIGNUP, notification.notification_type
  end

  test "notify_shift_signup sends email when enabled and email configured" do
    @village.update!(email_enabled: true, mailgun_api_key: "test-key", mailgun_domain: "test.mailgun.org")
    @user.update!(notify_in_app: false, notify_by_email: true)

    assert_enqueued_with(job: ActionMailer::MailDeliveryJob) do
      NotificationService.notify_shift_signup(user: @user, timeslot: @timeslot)
    end
  end

  test "notify_shift_signup does not send email when email disabled globally" do
    @village.update!(email_enabled: false)
    @user.update!(notify_in_app: false, notify_by_email: true)

    assert_no_enqueued_jobs only: ActionMailer::MailDeliveryJob do
      NotificationService.notify_shift_signup(user: @user, timeslot: @timeslot)
    end
  end

  test "notify_shift_signup creates both in-app and email when both enabled" do
    @village.update!(email_enabled: true, mailgun_api_key: "test-key", mailgun_domain: "test.mailgun.org")
    @user.update!(notify_in_app: true, notify_by_email: true)

    assert_difference("Notification.count", 1) do
      assert_enqueued_with(job: ActionMailer::MailDeliveryJob) do
        NotificationService.notify_shift_signup(user: @user, timeslot: @timeslot)
      end
    end
  end

  test "notify_shift_cancelled creates notification" do
    @user.update!(notify_in_app: true, notify_by_email: false)

    assert_difference("Notification.count", 1) do
      NotificationService.notify_shift_cancelled(user: @user, timeslot: @timeslot)
    end

    notification = @user.notifications.last
    assert_equal "Shift Cancelled", notification.title
    assert_equal Notification::SHIFT_CANCELLED, notification.notification_type
  end

  test "notify_shift_reminder creates notification" do
    @user.update!(notify_in_app: true, notify_by_email: false)

    assert_difference("Notification.count", 1) do
      NotificationService.notify_shift_reminder(user: @user, timeslot: @timeslot, minutes_before: 30)
    end

    notification = @user.notifications.last
    assert_equal "Shift Reminder", notification.title
    assert_includes notification.body, "30 minutes"
    assert_equal Notification::SHIFT_REMINDER, notification.notification_type
  end

  test "notify_admin_new_signup creates notification for admin" do
    @admin.update!(notify_in_app: true, notify_by_email: false)

    assert_difference("Notification.count", 1) do
      NotificationService.notify_admin_new_signup(admin: @admin, volunteer: @user, timeslot: @timeslot)
    end

    notification = @admin.notifications.last
    assert_equal "New Volunteer Signup", notification.title
    assert_includes notification.body, @user.email
    assert_equal Notification::ADMIN_ALERT, notification.notification_type
  end

  test "send_system_notification creates notification" do
    @user.update!(notify_in_app: true, notify_by_email: false)

    assert_difference("Notification.count", 1) do
      NotificationService.send_system_notification(
        user: @user,
        title: "System Alert",
        body: "Important system message"
      )
    end

    notification = @user.notifications.last
    assert_equal "System Alert", notification.title
    assert_equal "Important system message", notification.body
    assert_equal Notification::SYSTEM, notification.notification_type
  end

  test "does not create in-app notification when disabled" do
    @user.update!(notify_in_app: false, notify_by_email: false)

    assert_no_difference("Notification.count") do
      NotificationService.notify_shift_signup(user: @user, timeslot: @timeslot)
    end
  end
end
