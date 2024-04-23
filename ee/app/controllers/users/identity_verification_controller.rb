# frozen_string_literal: true

module Users
  class IdentityVerificationController < BaseIdentityVerificationController
    before_action :ensure_feature_enabled

    def show; end

    private

    def ensure_feature_enabled
      return not_found unless ::Feature.enabled?(:opt_in_identity_verification, @user, type: :wip)

      not_found unless ::Gitlab::Saas.feature_available?(:identity_verification)
    end
  end
end
