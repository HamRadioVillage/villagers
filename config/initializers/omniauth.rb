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

  # The userinfo claim holding the user's roles (a list of strings).
  def roles_claim
    ENV.fetch("OAUTH_ROLES_CLAIM", "roles")
  end

  # Optional access-control gate: a regular expression tested against each role
  # string. When unset, OAuth sign-in is open to anyone the provider
  # authenticates (the open-source default). When set, a user must have at least
  # one role matching the pattern to sign in (see OauthAccessPolicy).
  #
  # Returns a compiled Regexp or nil. Raises RegexpError on a malformed pattern;
  # this is exercised at boot below so a typo fails the deploy, not every login.
  def allowed_roles_pattern
    raw = ENV["OAUTH_ALLOWED_ROLES_REGEX"]
    return nil if raw.nil? || raw.empty?

    Regexp.new(raw)
  end
end

# Validate the access-control regex at boot so a malformed pattern surfaces
# immediately instead of failing closed on every login attempt.
begin
  VillagerOauthConfig.allowed_roles_pattern
rescue RegexpError => e
  raise "OAUTH_ALLOWED_ROLES_REGEX is not a valid regular expression: #{e.message}"
end
