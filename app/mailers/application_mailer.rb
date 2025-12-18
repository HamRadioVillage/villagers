class ApplicationMailer < ActionMailer::Base
  default from: -> { default_from_address }

  layout "mailer"

  private

  # Helper to check if email should be sent
  def email_enabled?
    Village.email_enabled?
  end

  # Use this in mailer actions to skip sending when email is disabled
  def skip_if_email_disabled
    unless email_enabled?
      mail.perform_deliveries = false
      return true
    end
    false
  end

  def default_from_address
    ENV.fetch("MAILER_FROM_ADDRESS", "notifications@example.com")
  end
end
