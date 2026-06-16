ENV["RAILS_ENV"] ||= "test"

# Dummy OAuth credentials so the OmniAuth provider/middleware is registered
# under test. Combined with OmniAuth.config.test_mode, no real HTTP is made.
ENV["OAUTH_CLIENT_ID"] ||= "test-oauth-client"
ENV["OAUTH_CLIENT_SECRET"] ||= "test-oauth-secret"
ENV["OAUTH_SITE"] ||= "https://oauth.test"

# Pin app-default values for flags a developer's local .env might override, so
# the suite is deterministic regardless of .env. Set before the environment
# boots; dotenv's non-overwriting load won't clobber these. Tests that exercise
# the non-default behavior stub the relevant predicate directly.
ENV["SELF_REGISTRATION_ENABLED"] = "true"   # self-registration on (app default)
ENV["OAUTH_ROLES_CLAIM"] = "roles"          # default roles claim key
ENV["OAUTH_ALLOWED_ROLES_REGEX"] = ""       # access gate off (empty => no pattern)

require_relative "../config/environment"
require "rails/test_help"

# Force routes to be loaded so Devise mappings are available
Rails.application.reload_routes!

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    # Disabled (threshold: 1000) due to Devise mapping race conditions with parallel processes
    # TODO: Re-enable when Devise fixes parallel test support or we have 1000+ tests
    parallelize(workers: :number_of_processors, threshold: 1000)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Add more helper methods to be used by all tests here...
  end
end

# Run OmniAuth in test mode so no real HTTP requests are made to the provider.
OmniAuth.config.test_mode = true
OmniAuth.config.logger = Rails.logger

# Build a fake OmniAuth auth hash for the villager_oauth provider and register
# it so the next request to the callback uses it. Pass overrides for
# uid/email/name and the provider `roles` claim (carried in extra.raw_info).
def stub_villager_oauth(uid: "oauth-uid-123", email: "oauth.user@example.com", name: "OAuth User", roles: [])
  auth = OmniAuth::AuthHash.new(
    provider: "villager_oauth",
    uid: uid,
    info: { email: email, name: name },
    extra: { raw_info: { "email" => email, "name" => name, "roles" => roles } }
  )
  OmniAuth.config.mock_auth[:villager_oauth] = auth
  Rails.application.env_config["omniauth.auth"] = auth
  auth
end

# Simulate a provider-side failure (e.g. user denied access, invalid token).
def stub_villager_oauth_failure(reason = :invalid_credentials)
  OmniAuth.config.mock_auth[:villager_oauth] = reason
end

# Include Devise test helpers
class ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  # Auto-confirm users in tests since email confirmation is enabled
  def create_confirmed_user(attrs = {})
    user = User.new({
      email: "test#{SecureRandom.hex(4)}@example.com",
      password: "password123",
      password_confirmation: "password123"
    }.merge(attrs))
    user.skip_confirmation!
    user.save!
    user
  end
end

class ActionDispatch::SystemTestCase
  include Devise::Test::IntegrationHelpers
end

# Auto-confirm all users created in test environment
User.class_eval do
  after_initialize do
    self.confirmed_at ||= Time.current if new_record? && Rails.env.test?
  end
end
