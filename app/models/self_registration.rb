# frozen_string_literal: true

# SelfRegistration controls whether visitors can create their own accounts
# through the Devise sign-up form.
#
# When disabled (SELF_REGISTRATION_ENABLED=false):
# - The "Sign up" link is hidden and the registration form is blocked.
# - Accounts can still be provisioned through OAuth single sign-on
#   (see User.from_omniauth) and created by administrators.
#
# Self-registration is ENABLED by default; set the env var to a falsey value to
# turn it off (e.g. for SSO-only deployments).
#
# Configuration via environment variables:
#   SELF_REGISTRATION_ENABLED=false   # Disable the public sign-up form
module SelfRegistration
  module_function

  def enabled?
    ActiveModel::Type::Boolean.new.cast(ENV.fetch("SELF_REGISTRATION_ENABLED", true))
  end

  def disabled?
    !enabled?
  end
end
