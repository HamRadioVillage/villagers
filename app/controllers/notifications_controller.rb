class NotificationsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_notification, only: [ :show, :destroy ]

  def index
    @notifications = current_user.notifications.recent.limit(100)
    @unread_count = current_user.unread_notifications_count
  end

  def show
    @notification.mark_as_read!
  end

  def mark_all_read
    current_user.notifications.unread.update_all(read_at: Time.current)
    redirect_to notifications_path, notice: "All notifications marked as read."
  end

  def destroy
    @notification.destroy
    redirect_to notifications_path, notice: "Notification deleted."
  end

  def bulk_destroy
    notification_ids = params[:notification_ids] || []
    current_user.notifications.where(id: notification_ids).destroy_all
    redirect_to notifications_path, notice: "Selected notifications deleted."
  end

  private

  def set_notification
    @notification = current_user.notifications.find(params[:id])
  end
end
