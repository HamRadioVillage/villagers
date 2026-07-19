module Api
  module V1
    # GET /api/v1/conferences/:conference_id/volunteers
    # GET /api/v1/conferences/:conference_id/volunteers/:id
    # Per-volunteer signed-up totals for a conference. Filters: user_id.
    class VolunteersController < BaseController
      def index
        conference = Conference.find(params[:conference_id])
        authorize conference, :index?, policy_class: Api::ConferenceVolunteerDataPolicy

        counts = scope_to_visible_volunteers(conference_signups(conference), conference)
                 .group(:user_id).count
        users = User.where(id: counts.keys).index_by(&:id)

        volunteers = counts.map { |user_id, shift_count| volunteer_json(users[user_id], shift_count) }
                           .sort_by { |volunteer| [ -volunteer[:shift_count], volunteer[:user_id] ] }

        render json: { conference_id: conference.id, volunteers: volunteers }
      end

      def show
        conference = Conference.find(params[:conference_id])
        authorize conference, :show?, policy_class: Api::ConferenceVolunteerDataPolicy

        policy = Api::ConferenceVolunteerDataPolicy.new(current_api_user, conference)
        unless policy.view_all_volunteers? || params[:id].to_i == current_api_user.id
          raise Pundit::NotAuthorizedError
        end

        volunteer = User.find(params[:id])
        shift_count = volunteer.shifts_for_conference(conference)

        render json: { conference_id: conference.id, volunteer: volunteer_json(volunteer, shift_count) }
      end

      private

      def volunteer_json(user, shift_count)
        {
          user_id: user.id,
          name: user.name,
          handle: user.handle,
          shift_count: shift_count,
          # Each signup is one 15-minute timeslot (see User#hours_for_conference)
          total_hours: shift_count * 0.25
        }
      end
    end
  end
end
