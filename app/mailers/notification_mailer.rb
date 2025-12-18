class NotificationMailer < ApplicationMailer
  def test_email(user)
    @user = user
    mail(
      to: user.email,
      subject: "Villagers Email Test"
    )
  end

  def notification_email(user:, title:, body:, notification_type:)
    @user = user
    @title = title
    @body = body
    @notification_type = notification_type
    @village_name = Village.first&.name || "Villagers"

    mail(
      to: @user.email,
      subject: "[#{@village_name}] #{@title}"
    )
  end
end
