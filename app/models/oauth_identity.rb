# frozen_string_literal: true

# Wraps an OmniAuth auth hash and exposes the bits of identity the app cares
# about. This is the shared seam for everything that reads provider claims:
# the login gate (OauthAccessPolicy) today, and role syncing later, so the
# claim layout is decoded in exactly one place.
class OauthIdentity
  def initialize(auth)
    @auth = auth
  end

  def uid
    @auth.uid.to_s
  end

  def email
    @auth.dig("info", "email")
  end

  def name
    @auth.dig("info", "name")
  end

  # The provider's roles claim as an array of strings (empty when absent).
  # Role strings are opaque here; the planned role sync interprets the
  # "rolename:conference" encoding (omitted scope = global).
  def roles
    Array(@auth.dig("extra", "raw_info", VillagerOauthConfig.roles_claim)).map(&:to_s)
  end
end
