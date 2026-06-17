require "omniauth-oauth2"

module OmniAuth
  module Strategies
    # Generic OAuth2 strategy for the village's existing (non-OIDC) OAuth2
    # provider. All endpoints, the userinfo path, and the field mappings are
    # driven by ENV so deployments differ only by configuration:
    #
    #   OAUTH_SITE           - provider base URL (e.g. https://auth.example.org)
    #   OAUTH_AUTHORIZE_URL  - authorize endpoint (absolute, or relative to site)
    #   OAUTH_TOKEN_URL      - token endpoint     (absolute, or relative to site)
    #   OAUTH_USERINFO_URL   - userinfo endpoint  (absolute, or relative to site)
    #   OAUTH_SCOPE          - requested scope(s) (default: "shifts")
    #   OAUTH_UID_FIELD      - userinfo key holding the unique id (default: "sub", the OIDC subject)
    #   OAUTH_EMAIL_FIELD    - userinfo key holding the email     (default: "email")
    #   OAUTH_NAME_FIELD     - userinfo key holding the name      (default: "name")
    #
    # NOTE: this is scaffolding. Confirm the real endpoint paths and userinfo
    # JSON shape with the provider and adjust the ENV defaults below if needed.
    class VillagerOauth < OmniAuth::Strategies::OAuth2
      option :name, "villager_oauth"

      option :client_options,
             site: ENV["OAUTH_SITE"],
             authorize_url: ENV.fetch("OAUTH_AUTHORIZE_URL", "/oauth/authorize"),
             token_url: ENV.fetch("OAUTH_TOKEN_URL", "/oauth/token")

      option :scope, ENV.fetch("OAUTH_SCOPE", "shifts")

      uid { raw_info[uid_field].to_s }

      info do
        {
          email: raw_info[email_field],
          name: raw_info[name_field]
        }
      end

      extra do
        { raw_info: raw_info }
      end

      def raw_info
        @raw_info ||= access_token.get(userinfo_url).parsed
      end

      # OAuth2 requires a redirect_uri identical on the authorize and token
      # requests; pin it to the callback so it stays stable behind proxies.
      def callback_url
        full_host + callback_path
      end

      private

      def userinfo_url
        ENV.fetch("OAUTH_USERINFO_URL", "/oauth/userinfo")
      end

      def uid_field
        ENV.fetch("OAUTH_UID_FIELD", "sub")
      end

      def email_field
        ENV.fetch("OAUTH_EMAIL_FIELD", "email")
      end

      def name_field
        ENV.fetch("OAUTH_NAME_FIELD", "name")
      end
    end
  end
end
