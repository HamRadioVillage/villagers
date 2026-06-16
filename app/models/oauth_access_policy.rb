# frozen_string_literal: true

# Decides whether an OAuth-authenticated identity is allowed to sign in, based
# on the provider's roles claim. This is authorization, kept separate from the
# strategy (authentication) and from User provisioning.
#
# - No pattern configured -> everyone the provider authenticates is allowed
#   (the open-source default).
# - Pattern configured     -> the identity must have at least one role matching
#   it; missing/empty roles or no match are denied (fail closed).
#
# Evaluated on every login so revoked access at the IdP takes effect immediately.
class OauthAccessPolicy
  def self.permitted?(identity)
    pattern = VillagerOauthConfig.allowed_roles_pattern
    return true if pattern.nil?

    identity.roles.any? { |role| pattern.match?(role) }
  end
end
