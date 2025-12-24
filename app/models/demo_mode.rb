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
# The reset schedule is tracked via a timestamp file written by the
# demo:reset rake task, allowing the banner to show accurate countdown.
#
# Configuration via environment variables:
#   DEMO_MODE=true                    # Enable demo mode
#   DEMO_BANNER_TEXT="Custom Text"    # Custom banner text (optional)
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

  TIMESTAMP_FILE = "demo_last_reset.txt"
  RESET_INTERVAL = 24.hours

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

    def banner_text
      ENV.fetch("DEMO_BANNER_TEXT") { "Demo Mode - Data resets daily" }
    end

    def timestamp_file_path
      Rails.root.join("tmp", TIMESTAMP_FILE)
    end

    def last_reset_time
      return nil unless File.exist?(timestamp_file_path)

      Time.parse(File.read(timestamp_file_path)).utc
    rescue ArgumentError
      nil
    end

    def record_reset!
      File.write(timestamp_file_path, Time.current.utc.iso8601)
    end

    def next_reset_time
      return nil unless last_reset_time

      last_reset_time + RESET_INTERVAL
    end

    def time_until_reset
      return nil unless next_reset_time

      next_reset_time - Time.current.utc
    end

    def formatted_time_until_reset
      remaining = time_until_reset
      return nil unless remaining

      seconds = remaining.to_i
      return nil if seconds <= 0

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
