# frozen_string_literal: true

# https://developer.telesign.com/enterprise/docs/transaction-callback-service
module PhoneVerification
  class TelesignCallbacksController < ApplicationController
    respond_to :json

    skip_before_action :authenticate_user!
    skip_before_action :verify_authenticity_token

    feature_category :instance_resiliency
    urgency :low

    def notify
      return not_found unless callback.valid?

      callback.log

      exempt_user_from_phone_number_verification if callback.payload.country_blocked?

      render json: {}
    end

    private

    def callback
      @callback ||= ::Telesign::TransactionCallback.new(request, params)
    end

    def exempt_user_from_phone_number_verification
      return unless ::Feature.enabled?(:auto_request_phone_number_verification_exemption, type: :gitlab_com_derisk)

      user = callback.user

      return unless user&.offer_phone_number_exemption?

      user.create_phone_number_exemption!
      Gitlab::EtagCaching::Store.new.touch(verification_state_identity_verification_path)
    end
  end
end
