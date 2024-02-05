# frozen_string_literal: true

module TrialRegistrationsHelper
  def social_signin_enabled?
    ::Onboarding::Status.enabled? &&
      omniauth_enabled? &&
      devise_mapping.omniauthable? &&
      button_based_providers_enabled?
  end
end
