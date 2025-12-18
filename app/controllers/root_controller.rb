class RootController < ApplicationController
  def show
    if Village.setup_complete?
      @village = Village.first
      load_dashboard_data if user_signed_in?
      render :show
    else
      redirect_to setup_path
    end
  end

  private

  def load_dashboard_data
    if current_user.village_admin?
      load_village_admin_data
    end

    if current_user.conference_lead_conferences.any? || current_user.conference_admin_conferences.any?
      load_conference_manager_data
    end

    # All users get volunteer data
    load_volunteer_data
  end

  def load_village_admin_data
    @active_conferences = Conference.active.order(start_date: :asc).limit(5)
    @archived_conferences_count = Conference.archived.count
    @total_programs = Program.count
    @total_users = User.count
    @total_volunteer_hours = VolunteerSignup.count * 0.25
    @recent_signups = VolunteerSignup.includes(user: [], timeslot: { conference_program: [ :conference, :program ] })
                                     .order(created_at: :desc)
                                     .limit(5)
  end

  def load_conference_manager_data
    managed_conference_ids = current_user.conference_roles.pluck(:conference_id)
    @managed_conferences = Conference.where(id: managed_conference_ids)
                                     .active
                                     .includes(:conference_programs)
                                     .order(start_date: :asc)

    # Conferences needing attention (low fill rate or upcoming with no programs)
    @conferences_needing_attention = @managed_conferences.select do |conf|
      conf.fill_rate < 50 || conf.programs_count == 0
    end

    # Get recent signups and consolidate consecutive timeslots into single entries
    recent_signups = VolunteerSignup.joins(timeslot: :conference_program)
                                    .where(conference_programs: { conference_id: managed_conference_ids })
                                    .includes(user: [], timeslot: { conference_program: [ :conference, :program ] })
                                    .order(created_at: :desc)
                                    .limit(50) # Load more to allow for consolidation

    @managed_recent_signups = consolidate_signups(recent_signups).first(5)
  end

  def consolidate_signups(signups)
    # Group signups by user, conference, program, and created_at time (within 1 minute window)
    groups = signups.group_by do |signup|
      [
        signup.user_id,
        signup.timeslot.conference_program_id,
        signup.created_at.to_i / 60 # Group by minute
      ]
    end

    # Convert each group into a consolidated signup entry
    groups.map do |_key, group_signups|
      sorted = group_signups.sort_by { |s| s.timeslot.start_time }
      first_signup = sorted.first
      last_signup = sorted.last

      {
        user: first_signup.user,
        conference: first_signup.timeslot.conference_program.conference,
        program: first_signup.timeslot.conference_program.program,
        start_time: first_signup.timeslot.start_time,
        end_time: last_signup.timeslot.start_time + 15.minutes,
        created_at: first_signup.created_at,
        shift_count: group_signups.size
      }
    end.sort_by { |s| -s[:created_at].to_i }
  end

  def load_volunteer_data
    @my_upcoming_shifts = current_user.volunteer_signups
                                      .joins(timeslot: :conference_program)
                                      .includes(timeslot: { conference_program: [ :conference, :program ] })
                                      .where("timeslots.start_time > ?", Time.current)
                                      .order("timeslots.start_time ASC")
                                      .limit(5)

    @my_total_shifts = current_user.total_shifts
    @my_total_hours = current_user.total_volunteer_hours
    @my_conferences_count = current_user.conferences_participated_count

    # My qualifications
    @my_qualifications = current_user.qualifications.order(:name)

    # Get conferences the user has signed up for
    signed_up_conference_ids = current_user.volunteer_signups
                                           .joins(timeslot: :conference_program)
                                           .select("conference_programs.conference_id")
                                           .distinct
                                           .pluck("conference_programs.conference_id")

    # My conferences - conferences I'm volunteering for (active/upcoming first)
    @my_volunteering_conferences = Conference.where(id: signed_up_conference_ids)
                                             .where("end_date >= ?", Date.current)
                                             .order(start_date: :asc)
                                             .limit(5)
                                             .map do |conference|
      {
        conference: conference,
        shifts_count: current_user.shifts_for_conference(conference)
      }
    end

    # Open opportunities - conferences with available shifts (excluding ones we've signed up for)
    @open_conferences = Conference.active
                                  .where("end_date >= ?", Date.current)
                                  .where.not(id: signed_up_conference_ids)
                                  .includes(:conference_programs)
                                  .select { |c| c.unfilled_timeslots > 0 }
                                  .first(3)
  end
end
