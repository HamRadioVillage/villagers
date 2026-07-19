module Api
  # Governs read access to per-volunteer data (hours totals, shift detail)
  # exposed by the API for a conference. The record is the Conference.
  class ConferenceVolunteerDataPolicy < ApplicationPolicy
    # Any authenticated user may hit the endpoints; what they can see is
    # narrowed by view_all_volunteers? below.
    def index?
      user.present?
    end

    def view_all_volunteers?
      user.present? && user.can_manage_conference?(record)
    end
  end
end
