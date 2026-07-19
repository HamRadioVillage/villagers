module Api
  module V1
    # Base for all /api/v1 endpoints: JSON-only, authenticated via a personal
    # API token (Authorization: Bearer vlg_...) or an existing Devise session
    # (for same-origin callers), with JSON error responses throughout.
    class BaseController < ActionController::API
      include Pundit::Authorization
      include ActionController::HttpAuthentication::Token::ControllerMethods

      before_action :authenticate_api_user!

      rescue_from Pundit::NotAuthorizedError, with: :render_forbidden
      rescue_from ActiveRecord::RecordNotFound, with: :render_not_found

      attr_reader :current_api_user

      def pundit_user
        current_api_user
      end

      private

      def authenticate_api_user!
        @current_api_user = user_from_bearer_token || user_from_session
        return if @current_api_user

        response.set_header("WWW-Authenticate", 'Bearer realm="Villagers API"')
        render json: { error: "unauthorized" }, status: :unauthorized
      end

      def user_from_bearer_token
        authenticate_with_http_token do |token, _options|
          api_token = ApiToken.authenticate(token)
          next nil unless api_token

          api_token.touch_last_used
          api_token.user
        end
      end

      def user_from_session
        request.env["warden"]&.user(:user)
      end

      # All signups belonging to a conference (via timeslot -> conference_program).
      def conference_signups(conference)
        VolunteerSignup.joins(timeslot: :conference_program)
                       .where(conference_programs: { conference_id: conference.id })
      end

      # Restricts a VolunteerSignup relation to what the caller may see:
      # conference managers see everyone (optionally narrowed by ?user_id=),
      # everyone else is pinned to their own rows. Asking for someone else's
      # rows without manager rights raises Pundit::NotAuthorizedError (403).
      def scope_to_visible_volunteers(scope, conference)
        requested_id = params[:user_id].presence&.to_i
        policy = Api::ConferenceVolunteerDataPolicy.new(current_api_user, conference)

        if policy.view_all_volunteers?
          requested_id ? scope.where(user_id: requested_id) : scope
        elsif requested_id && requested_id != current_api_user.id
          raise Pundit::NotAuthorizedError
        else
          scope.where(user_id: current_api_user.id)
        end
      end

      def render_forbidden
        render json: { error: "forbidden" }, status: :forbidden
      end

      def render_not_found
        render json: { error: "not_found" }, status: :not_found
      end
    end
  end
end
