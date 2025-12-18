class CleanupOldNotificationsJob < ApplicationJob
  queue_as :default

  def perform
    # Delete notifications that have been read more than 30 days ago
    deleted_count = Notification.old_read.delete_all
    Rails.logger.info "CleanupOldNotificationsJob: Deleted #{deleted_count} old notifications"
  end
end
