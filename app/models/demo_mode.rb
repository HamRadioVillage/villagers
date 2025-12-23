# frozen_string_literal: true

# DemoMode provides configuration and utilities for running Villagers
# as a publicly accessible demonstration instance.
#
# When enabled via DEMO_MODE=true:
# - Email sending is disabled
# - User accounts are auto-confirmed
# - A demo banner is displayed
# - Demo credentials are shown on login
# - Seed demo accounts are protected from deletion
#
# Configuration via environment variables:
#   DEMO_MODE=true                    # Enable demo mode
#   DEMO_RESET_HOUR=4                 # Hour (UTC) to reset database
#   DEMO_BANNER_TEXT="Custom Text"    # Custom banner text
module DemoMode
  PROTECTED_EMAILS = %w[
    admin@example.com
    coordinator@example.com
    admin1@example.com
    admin2@example.com
    volunteer1@example.com
    volunteer2@example.com
    volunteer3@example.com
    volunteer4@example.com
    volunteer5@example.com
  ].freeze

  class << self
    def enabled?
      ActiveModel::Type::Boolean.new.cast(ENV.fetch("DEMO_MODE", false))
    end

    def disabled?
      !enabled?
    end

    def protected_email?(email)
      PROTECTED_EMAILS.include?(email.to_s.downcase)
    end

    def demo_credentials
      [
        { email: "admin@example.com", password: "password", role: "Village Admin" },
        { email: "coordinator@example.com", password: "password", role: "Conference Lead" },
        { email: "volunteer1@example.com", password: "password", role: "Volunteer" }
      ]
    end

    def reset_hour
      ENV.fetch("DEMO_RESET_HOUR", 4).to_i
    end

    def banner_text
      ENV.fetch("DEMO_BANNER_TEXT") { "Demo Mode - Data resets daily at #{reset_hour}:00 AM UTC" }
    end

    def next_reset_time
      now = Time.current.utc
      reset_time = now.change(hour: reset_hour, min: 0, sec: 0)
      reset_time += 1.day if now >= reset_time
      reset_time
    end

    def time_until_reset
      next_reset_time - Time.current.utc
    end

    def formatted_time_until_reset
      seconds = time_until_reset.to_i
      hours = seconds / 3600
      minutes = (seconds % 3600) / 60

      if hours > 0
        "#{hours}h #{minutes}m"
      else
        "#{minutes}m"
      end
    end
  end
end
