module Users
  class RegistrationsController < Devise::RegistrationsController
    # Block only the public sign-up actions when self-registration is disabled.
    # Account management (edit/update/destroy) and OAuth-provisioned accounts are
    # unaffected, since those don't go through #new/#create.
    prepend_before_action :ensure_self_registration_enabled, only: [ :new, :create ]

    private

    def ensure_self_registration_enabled
      return if SelfRegistration.enabled?

      redirect_to new_user_session_path,
                  alert: "Self-registration is disabled. Please sign in or contact an administrator."
    end
  end
end
