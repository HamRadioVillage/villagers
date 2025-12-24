# frozen_string_literal: true

# Demo Seeds - Enhanced seed data for demo mode
# This file creates a more comprehensive dataset for demonstration purposes

puts "Creating demo seed data..."

# Create village with email disabled for demo
village = Village.find_or_create_by!(name: "Ham Radio Village") do |v|
  v.setup_complete = true
  v.email_enabled = false
end

# Update existing village to have email disabled
village.update!(email_enabled: false) if village.email_enabled?

puts "  Village: #{village.name} (email disabled for demo)"

# Create village admin role
village_admin_role = Role.find_or_create_by!(name: Role::VILLAGE_ADMIN)

# Create village admin
village_admin = User.find_or_create_by!(email: "admin@example.com") do |u|
  u.password = "password"
  u.password_confirmation = "password"
  u.name = "Village Administrator"
  u.handle = "VillageAdmin"
end
UserRole.find_or_create_by!(user: village_admin, role: village_admin_role)
puts "  Village Admin: #{village_admin.email}"

# Create multiple conferences (past, current, future)
conferences = []

# Past conference
past_conference = Conference.find_or_create_by!(name: "DEF CON 31", village: village) do |c|
  c.country = "US"
  c.state = "NV"
  c.city = "Las Vegas"
  c.start_date = Date.new(2023, 8, 10)
  c.end_date = Date.new(2023, 8, 13)
  c.conference_hours_start = Time.parse("10:00")
  c.conference_hours_end = Time.parse("18:00")
  c.archived_at = Time.current
end
conferences << past_conference
puts "  Past Conference: #{past_conference.name}"

# Current/Recent conference
current_conference = Conference.find_or_create_by!(name: "DEF CON 32", village: village) do |c|
  c.country = "US"
  c.state = "NV"
  c.city = "Las Vegas"
  c.start_date = Date.new(2024, 8, 8)
  c.end_date = Date.new(2024, 8, 11)
  c.conference_hours_start = Time.parse("09:00")
  c.conference_hours_end = Time.parse("18:00")
end
conferences << current_conference
puts "  Current Conference: #{current_conference.name}"

# Future conference
future_conference = Conference.find_or_create_by!(name: "DEF CON 33", village: village) do |c|
  c.country = "US"
  c.state = "NV"
  c.city = "Las Vegas"
  c.start_date = Date.new(2025, 8, 7)
  c.end_date = Date.new(2025, 8, 10)
  c.conference_hours_start = Time.parse("10:00")
  c.conference_hours_end = Time.parse("19:00")
end
conferences << future_conference
puts "  Future Conference: #{future_conference.name}"

# Create conference lead
conference_lead = User.find_or_create_by!(email: "coordinator@example.com") do |u|
  u.password = "password"
  u.password_confirmation = "password"
  u.name = "Conference Coordinator"
  u.handle = "CoordLead"
end
conferences.each do |conf|
  ConferenceRole.find_or_create_by!(
    user: conference_lead,
    conference: conf,
    role_name: ConferenceRole::CONFERENCE_LEAD
  )
end
puts "  Conference Lead: #{conference_lead.email}"

# Create conference admins
admin_users = []
2.times do |i|
  admin = User.find_or_create_by!(email: "admin#{i + 1}@example.com") do |u|
    u.password = "password"
    u.password_confirmation = "password"
    u.name = "Conference Admin #{i + 1}"
    u.handle = "Admin#{i + 1}"
  end
  admin_users << admin

  # Assign to current and future conferences
  [ current_conference, future_conference ].each do |conf|
    ConferenceRole.find_or_create_by!(
      user: admin,
      conference: conf,
      role_name: ConferenceRole::CONFERENCE_ADMIN
    )
  end
end
puts "  Conference Admins: #{admin_users.map(&:email).join(', ')}"

# Create volunteers
volunteer_users = []
5.times do |i|
  volunteer = User.find_or_create_by!(email: "volunteer#{i + 1}@example.com") do |u|
    u.password = "password"
    u.password_confirmation = "password"
    u.name = "Demo Volunteer #{i + 1}"
    u.handle = "Vol#{i + 1}"
  end
  volunteer_users << volunteer
end
puts "  Volunteers: volunteer1@example.com through volunteer5@example.com"

# Create programs
programs = []

program_data = [
  { name: "Fox Hunting", description: "Radio direction finding competitions and training" },
  { name: "Kit Building", description: "Hands-on electronics kit assembly workshops" },
  { name: "Antenna Building", description: "Learn to build various amateur radio antennas" },
  { name: "License Exams", description: "Amateur radio license examination sessions" },
  { name: "On-Air Operations", description: "Live amateur radio operations and demonstrations" }
]

program_data.each do |data|
  program = Program.find_or_create_by!(name: data[:name], village: village) do |p|
    p.description = data[:description]
  end
  programs << program
end
puts "  Programs: #{programs.map(&:name).join(', ')}"

# Create conference programs for current and future conferences
[ current_conference, future_conference ].each do |conf|
  programs.each_with_index do |program, idx|
    cp = ConferenceProgram.find_or_create_by!(conference: conf, program: program) do |c|
      c.public_description = "#{program.name} at #{conf.name}"
      c.max_volunteers = [ 2, 3, 4 ].sample
    end

    # Create day schedules with timeslots for the first 3 programs
    if idx < 3 && cp.timeslots.empty?
      conf.conference_days.each do |day|
        # Morning session
        start_time = conf.conference_hours_start
        4.times do |slot|
          Timeslot.find_or_create_by!(
            conference_program: cp,
            date: day,
            start_time: start_time + (slot * 15).minutes
          ) do |t|
            t.max_volunteers = cp.max_volunteers
          end
        end

        # Afternoon session
        start_time = conf.conference_hours_start + 4.hours
        4.times do |slot|
          Timeslot.find_or_create_by!(
            conference_program: cp,
            date: day,
            start_time: start_time + (slot * 15).minutes
          ) do |t|
            t.max_volunteers = cp.max_volunteers
          end
        end
      end
    end
  end
end
puts "  Conference programs and timeslots created"

# Create some sample volunteer signups for the current conference
current_conference.conference_programs.each do |cp|
  cp.timeslots.limit(3).each_with_index do |timeslot, idx|
    volunteer = volunteer_users[idx % volunteer_users.size]
    VolunteerSignup.find_or_create_by!(user: volunteer, timeslot: timeslot)
  end
end
puts "  Sample volunteer signups created"

# Create qualifications
qualifications = []
qual_data = [
  { name: "Licensed Ham", description: "Must hold a valid amateur radio license" },
  { name: "Soldering Certified", description: "Completed soldering safety training" },
  { name: "VE Certified", description: "Certified Volunteer Examiner" }
]

qual_data.each do |data|
  qual = Qualification.find_or_create_by!(name: data[:name], village: village) do |q|
    q.description = data[:description]
  end
  qualifications << qual
end
puts "  Qualifications: #{qualifications.map(&:name).join(', ')}"

# Assign qualifications to some volunteers
volunteer_users.first(3).each do |volunteer|
  qualifications.first(2).each do |qual|
    UserQualification.find_or_create_by!(user: volunteer, qualification: qual)
  end
end
puts "  Qualifications assigned to volunteers"

puts "\nDemo seed data created successfully!"
puts "\nDemo Accounts:"
puts "  Village Admin:     admin@example.com / password"
puts "  Conference Lead:   coordinator@example.com / password"
puts "  Conference Admin:  admin1@example.com / password"
puts "  Volunteer:         volunteer1@example.com / password"
puts "\nAll accounts use password: password"
