class NotificationPreferencesController < ApplicationController
  before_action :authenticate_user!

  def update
    if current_user.update(notification_preferences_params)
      redirect_to edit_user_registration_path, notice: "Notification preferences updated."
    else
      redirect_to edit_user_registration_path, alert: "Failed to update notification preferences."
    end
  end

  private

  def notification_preferences_params
    params.require(:user).permit(:notify_by_email, :notify_in_app)
  end
end
