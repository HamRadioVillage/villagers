# frozen_string_literal: true

# Mailgun API delivery method for Action Mailer
# This allows sending emails via Mailgun's REST API instead of SMTP
#
# Required environment variables:
#   MAILGUN_API_KEY - Your Mailgun API key
#   MAILGUN_DOMAIN  - Your Mailgun sending domain (e.g., sandbox123.mailgun.org)
#
# Optional environment variables:
#   MAILGUN_REGION  - "us" (default) or "eu" for EU region

class MailgunDeliveryMethod
  attr_reader :settings

  def initialize(settings)
    @settings = settings
  end

  def deliver!(mail)
    # Try Village settings first, then fall back to environment variables
    village_settings = village_mailgun_settings
    api_key = village_settings[:api_key] || settings[:api_key] || ENV.fetch("MAILGUN_API_KEY", nil)
    domain = village_settings[:domain] || settings[:domain] || ENV.fetch("MAILGUN_DOMAIN", nil)
    region = village_settings[:region] || settings[:region] || ENV.fetch("MAILGUN_REGION", "us")

    raise ArgumentError, "Mailgun API key is required" if api_key.blank?
    raise ArgumentError, "Mailgun domain is required" if domain.blank?

    # Configure Mailgun client based on region
    api_host = region == "eu" ? "api.eu.mailgun.net" : "api.mailgun.net"

    mg_client = Mailgun::Client.new(api_key, api_host)
    message_builder = Mailgun::MessageBuilder.new

    # Build the message
    message_builder.from(mail.from.first)
    mail.to.each { |recipient| message_builder.add_recipient(:to, recipient) }
    mail.cc&.each { |recipient| message_builder.add_recipient(:cc, recipient) }
    mail.bcc&.each { |recipient| message_builder.add_recipient(:bcc, recipient) }

    message_builder.subject(mail.subject)

    # Handle multipart emails
    if mail.multipart?
      mail.parts.each do |part|
        if part.content_type.start_with?("text/plain")
          message_builder.body_text(part.body.decoded)
        elsif part.content_type.start_with?("text/html")
          message_builder.body_html(part.body.decoded)
        end
      end
    elsif mail.content_type&.start_with?("text/html")
      message_builder.body_html(mail.body.decoded)
    else
      message_builder.body_text(mail.body.decoded)
    end

    # Send the message
    mg_client.send_message(domain, message_builder)
  end

  private

  def village_mailgun_settings
    return {} unless defined?(Village) && Village.table_exists?

    Village.mailgun_settings
  rescue ActiveRecord::StatementInvalid
    # Handle case where database isn't ready yet
    {}
  end
end

# Register the delivery method with Action Mailer
ActionMailer::Base.add_delivery_method :mailgun, MailgunDeliveryMethod
