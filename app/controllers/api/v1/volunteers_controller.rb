module Api
  module V1
    # GET /api/v1/conferences/:conference_id/volunteers
    # Per-volunteer signed-up totals for a conference. Filters: user_id.
    class VolunteersController < BaseController
      def index
        conference = Conference.find(params[:conference_id])
        authorize conference, :index?, policy_class: Api::ConferenceVolunteerDataPolicy

        scope = VolunteerSignup.joins(timeslot: :conference_program)
                               .where(conference_programs: { conference_id: conference.id })
        counts = scope_to_visible_volunteers(scope, conference).group(:user_id).count
        users = User.where(id: counts.keys).index_by(&:id)

        volunteers = counts.map do |user_id, shift_count|
          user = users[user_id]
          {
            user_id: user_id,
            name: user.name,
            handle: user.handle,
            shift_count: shift_count,
            # Each signup is one 15-minute timeslot (see User#hours_for_conference)
            total_hours: shift_count * 0.25
          }
        end.sort_by { |volunteer| [ -volunteer[:shift_count], volunteer[:user_id] ] }

        render json: { conference_id: conference.id, volunteers: volunteers }
      end
    end
  end
end
