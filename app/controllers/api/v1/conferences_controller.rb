module Api
  module V1
    # GET /api/v1/conferences
    # Event-level details for every conference, newest first.
    class ConferencesController < BaseController
      def index
        authorize Conference, :index?, policy_class: ConferencePolicy

        conferences = Conference.order(start_date: :desc).map do |conference|
          {
            id: conference.id,
            name: conference.name,
            city: conference.city,
            state: conference.state,
            country: conference.country,
            start_date: conference.start_date&.iso8601,
            end_date: conference.end_date&.iso8601,
            hours_start: conference.conference_hours_start&.strftime("%H:%M"),
            hours_end: conference.conference_hours_end&.strftime("%H:%M"),
            archived: conference.archived?
          }
        end

        render json: { conferences: conferences }
      end
    end
  end
end
