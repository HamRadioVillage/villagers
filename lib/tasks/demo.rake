# frozen_string_literal: true

namespace :demo do
  desc "Reset the demo database - drops, recreates, migrates, and seeds"
  task reset: :environment do
    unless DemoMode.enabled?
      puts "ERROR: DEMO_MODE is not enabled. Set DEMO_MODE=true to run this task."
      exit 1
    end

    puts "=" * 60
    puts "Demo Database Reset"
    puts "Started at: #{Time.current}"
    puts "=" * 60

    # Clear all sessions
    puts "\n[1/5] Clearing sessions..."
    begin
      ActiveRecord::SessionStore::Session.delete_all if defined?(ActiveRecord::SessionStore)
      puts "      Sessions cleared"
    rescue StandardError => e
      puts "      No session store to clear (#{e.message})"
    end

    # Drop and recreate database
    puts "\n[2/5] Dropping database..."
    Rake::Task["db:drop"].invoke
    puts "      Database dropped"

    puts "\n[3/5] Creating database..."
    Rake::Task["db:create"].invoke
    puts "      Database created"

    # Run migrations
    puts "\n[4/5] Running migrations..."
    Rake::Task["db:migrate"].invoke
    puts "      Migrations complete"

    # Seed database
    puts "\n[5/5] Seeding database..."
    Rake::Task["db:seed"].invoke
    puts "      Seeding complete"

    puts "\n" + "=" * 60
    puts "Demo reset completed at: #{Time.current}"
    puts "Next reset scheduled for: #{DemoMode.next_reset_time}"
    puts "=" * 60
  end

  desc "Show demo mode status"
  task status: :environment do
    puts "Demo Mode Status"
    puts "-" * 40
    puts "Enabled:           #{DemoMode.enabled?}"
    puts "Reset Hour (UTC):  #{DemoMode.reset_hour}:00"
    puts "Banner Text:       #{DemoMode.banner_text}"

    if DemoMode.enabled?
      puts "Next Reset:        #{DemoMode.next_reset_time}"
      puts "Time Until Reset:  #{DemoMode.formatted_time_until_reset}"
    end

    puts "-" * 40
    puts "\nProtected Accounts:"
    DemoMode::PROTECTED_EMAILS.each do |email|
      puts "  - #{email}"
    end
  end

  desc "Seed demo data only (without database reset)"
  task seed: :environment do
    puts "Loading demo seed data..."
    load Rails.root.join("db/seeds/demo_seeds.rb")
  end
end
