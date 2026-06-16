module Users
  class OmniauthCallbacksController < Devise::OmniauthCallbacksController
    # GET/POST /users/auth/villager_oauth/callback
    def villager_oauth
      auth = request.env["omniauth.auth"]
      identity = OauthIdentity.new(auth)

      # Authorization gate: only provision/sign in users whose roles claim
      # satisfies OAUTH_ALLOWED_ROLES_REGEX (no-op when that isn't configured).
      # Re-checked every login so revoked access at the IdP takes effect.
      unless OauthAccessPolicy.permitted?(identity)
        redirect_to new_user_session_path,
                    alert: "Your account isn't authorized to access this village."
        return
      end

      @user = User.from_omniauth(auth)

      if @user.persisted?
        sign_in_and_redirect @user, event: :authentication
        set_flash_message(:notice, :success, kind: VillagerOauthConfig.display_name) if is_navigational_format?
      else
        # Persisted? false means validation failed (e.g. email already taken by
        # an account we won't link, or missing required attributes).
        session["devise.villager_oauth_data"] = auth.except("extra")
        redirect_to new_user_session_path,
                    alert: @user.errors.full_messages.to_sentence.presence || "Could not sign you in."
      end
    end

    # Called by OmniAuth when the provider denies access or the flow errors out.
    def failure
      redirect_to new_user_session_path, alert: "Authentication failed. Please try again."
    end
  end
end
