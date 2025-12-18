class Notification < ApplicationRecord
  belongs_to :user

  validates :title, presence: true
  validates :body, presence: true
  validates :notification_type, presence: true

  # Notification types
  SHIFT_SIGNUP = "shift_signup"
  SHIFT_REMINDER = "shift_reminder"
  SHIFT_CANCELLED = "shift_cancelled"
  ADMIN_ALERT = "admin_alert"
  SYSTEM = "system"

  TYPES = [
    SHIFT_SIGNUP,
    SHIFT_REMINDER,
    SHIFT_CANCELLED,
    ADMIN_ALERT,
    SYSTEM
  ].freeze

  validates :notification_type, inclusion: { in: TYPES }

  # Scopes
  scope :unread, -> { where(read_at: nil) }
  scope :read, -> { where.not(read_at: nil) }
  scope :recent, -> { order(created_at: :desc) }
  scope :old_read, -> { read.where("read_at < ?", 30.days.ago) }

  def read?
    read_at.present?
  end

  def unread?
    !read?
  end

  def mark_as_read!
    update!(read_at: Time.current) if unread?
  end
end
