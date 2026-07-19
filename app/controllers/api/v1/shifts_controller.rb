module Api
  module V1
    # GET /api/v1/conferences/:conference_id/shifts
    # GET /api/v1/conferences/:conference_id/shifts/:id
    # Shift-level detail for a conference, ordered by start time.
    # Filters: user_id, program_id, from/to (ISO 8601, on timeslot start_time).
    class ShiftsController < BaseController
      def index
        conference = Conference.find(params[:conference_id])
        authorize conference, :index?, policy_class: Api::ConferenceVolunteerDataPolicy

        scope = scope_to_visible_volunteers(conference_signups(conference), conference)
        scope = apply_filters(scope)
        return if performed?

        shifts = scope.includes(timeslot: { conference_program: :program })
                      .order("timeslots.start_time")
                      .map { |signup| shift_json(signup) }

        render json: { conference_id: conference.id, shifts: shifts }
      end

      def show
        conference = Conference.find(params[:conference_id])
        authorize conference, :show?, policy_class: Api::ConferenceVolunteerDataPolicy

        # Non-managers are scoped to their own signups, so someone else's
        # shift id is indistinguishable from a nonexistent one (404).
        signup = scope_to_visible_volunteers(conference_signups(conference), conference)
                 .includes(timeslot: { conference_program: :program })
                 .find(params[:id])

        render json: { conference_id: conference.id, shift: shift_json(signup) }
      end

      private

      def shift_json(signup)
        {
          id: signup.id,
          user_id: signup.user_id,
          program: signup.timeslot.conference_program.program.name,
          starts_at: signup.timeslot.start_time.utc.iso8601,
          ends_at: signup.timeslot.end_time.utc.iso8601
        }
      end

      def apply_filters(scope)
        if params[:program_id].present?
          scope = scope.where(conference_programs: { program_id: params[:program_id] })
        end
        from = parse_time(:from)
        return scope if performed?
        scope = scope.where(timeslots: { start_time: from.. }) if from

        to = parse_time(:to)
        return scope if performed?
        scope = scope.where(timeslots: { start_time: ..to }) if to

        scope
      end

      def parse_time(key)
        return nil if params[key].blank?

        Time.iso8601(params[key])
      rescue ArgumentError
        render json: { error: "invalid_date" }, status: :bad_request
        nil
      end
    end
  end
end
