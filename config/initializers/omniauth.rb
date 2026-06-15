# Loads the custom OAuth2 strategy (lib/ subtree is excluded from Zeitwerk
# autoloading because the constant is `OmniAuth`, not `Omniauth`).
require Rails.root.join("lib/omniauth/strategies/villager_oauth")

# OAuth is only wired up when a client id is configured. This keeps the app
# bootable for open-source deployments that don't use SSO, and lets views hide
# the "Sign in with ..." button when it isn't available.
module VillagerOauthConfig
  module_function

  def enabled?
    ENV["OAUTH_CLIENT_ID"].present?
  end

  # Human-friendly provider name shown on the sign-in button.
  def display_name
    ENV.fetch("OAUTH_PROVIDER_NAME", "SSO")
  end
end
