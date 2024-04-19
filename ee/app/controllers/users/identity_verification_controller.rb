# frozen_string_literal: true

module Users
  class IdentityVerificationController < BaseIdentityVerificationController
    before_action :ensure_feature_enabled

    def show; end

    private

    def ensure_feature_enabled
      not_found unless ::Feature.enabled?(:opt_in_identity_verification, @user, type: :wip)
    end
  end
end
