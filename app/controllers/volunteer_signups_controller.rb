class VolunteerSignupsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_conference
  before_action :set_timeslot, only: [ :create ]
  before_action :set_volunteer_signup, only: [ :destroy ]

  def index
    authorize @conference, :show?, policy_class: ConferencePolicy
    @my_signups = current_user.volunteer_signups.joins(:timeslot)
                              .where(timeslots: { conference_program_id: @conference.conference_programs.pluck(:id) })
                              .includes(timeslot: [ :conference_program, :program ])
                              .order("timeslots.start_time")
  end

  def create
    @volunteer_signup = VolunteerSignup.new(user: current_user, timeslot: @timeslot)

    if @volunteer_signup.save
      redirect_to conference_volunteer_signups_path(@timeslot.conference), notice: "Successfully signed up for this shift."
    else
      redirect_to conference_volunteer_signups_path(@timeslot.conference), alert: @volunteer_signup.errors.full_messages.join(", ")
    end
  end

  def bulk_create
    start_timeslot = Timeslot.find(params[:timeslot_id])
    conference_program = start_timeslot.conference_program

    # Calculate end time from duration or use provided end_time
    if params[:duration_minutes].present?
      end_time = start_timeslot.start_time + params[:duration_minutes].to_i.minutes
    else
      end_time = Time.zone.parse(params[:end_time])
    end

    # Find all timeslots in the range for this program
    timeslots = conference_program.timeslots
                                  .where("start_time >= ? AND start_time < ?", start_timeslot.start_time, end_time)
                                  .order(:start_time)

    # Get user's existing signups for these timeslots
    existing_signup_ids = current_user.volunteer_signups
                                      .where(timeslot_id: timeslots.pluck(:id))
                                      .pluck(:timeslot_id)
                                      .to_set

    # Filter to timeslots user isn't already signed up for
    timeslots_to_signup = timeslots.reject { |ts| existing_signup_ids.include?(ts.id) }

    # Check if any timeslot is full
    full_timeslots = timeslots_to_signup.select(&:full?)
    if full_timeslots.any?
      redirect_to conference_schedule_path(@conference),
                  alert: "Cannot sign up: Some timeslots are full (#{full_timeslots.first.start_time.strftime('%l:%M %p').strip})"
      return
    end

    # Create signups in a transaction
    created_count = 0
    ActiveRecord::Base.transaction do
      timeslots_to_signup.each do |timeslot|
        signup = VolunteerSignup.new(user: current_user, timeslot: timeslot)
        if signup.save
          created_count += 1
        else
          raise ActiveRecord::Rollback, signup.errors.full_messages.join(", ")
        end
      end
    end

    total_minutes = created_count * 15
    hours = total_minutes / 60
    minutes = total_minutes % 60
    duration_str = hours > 0 ? "#{hours} hour#{'s' if hours > 1}" : ""
    duration_str += " #{minutes} minutes" if minutes > 0

    redirect_to conference_volunteer_signups_path(@conference),
                notice: "Successfully signed up for #{created_count} shifts (#{duration_str.strip})."
  end

  def available_timeslots
    start_timeslot = Timeslot.find(params[:timeslot_id])
    conference_program = start_timeslot.conference_program

    # Get all future timeslots for this program on the same day
    day_end = start_timeslot.start_time.end_of_day
    timeslots = conference_program.timeslots
                                  .where("start_time >= ? AND start_time < ?", start_timeslot.start_time, day_end)
                                  .order(:start_time)

    # Get user's existing signups
    existing_signup_ids = current_user.volunteer_signups
                                      .where(timeslot_id: timeslots.pluck(:id))
                                      .pluck(:timeslot_id)
                                      .to_set

    # Build available end times (only consecutive available slots)
    available_end_times = []
    timeslots.each do |ts|
      is_available = !ts.full? || existing_signup_ids.include?(ts.id)
      break unless is_available # Stop at first unavailable slot

      available_end_times << {
        end_time: ts.end_time.iso8601,
        display: ts.end_time.strftime("%l:%M %p").strip,
        duration_minutes: ((ts.end_time - start_timeslot.start_time) / 60).to_i,
        slots_count: available_end_times.length + 1
      }
    end

    render json: {
      start_time: start_timeslot.start_time.iso8601,
      start_time_display: start_timeslot.start_time.strftime("%l:%M %p").strip,
      program_name: conference_program.program.name,
      available_end_times: available_end_times
    }
  end

  def destroy
    @volunteer_signup.destroy
    redirect_to conference_volunteer_signups_path(@conference), notice: "Signup cancelled successfully."
  end

  private

  def set_conference
    @conference = Conference.find(params[:conference_id])
  end

  def set_timeslot
    @timeslot = Timeslot.find(params[:timeslot_id])
  end

  def set_volunteer_signup
    @volunteer_signup = current_user.volunteer_signups.find(params[:id])
  end
end
