# frozen_string_literal: true

# Service to synchronize JWT Service AccessToken issued by CustomersDot application
module Ai
  class SyncServiceAccessTokenService
    include ActiveModel::Validations

    validate :validate_license

    def execute
      return error_response(errors.full_messages.join(", ")) unless valid?

      response = client.get_service_token(license_key)

      return error_response(response[:errors].join(", ")) unless response[:success]

      storage_response = ServiceAccessTokensStorageService.new(response[:token], response[:expires_at]).execute

      return error_response(storage_response[:message]) if storage_response.error?

      ServiceResponse.success
    end

    private

    def client
      Gitlab::SubscriptionPortal::Client
    end

    def validate_license
      if license
        errors.add(:license, 'is not an online cloud license') unless license.online_cloud_license?
        errors.add(:license, 'grace period has been expired') if license.grace_period_expired?
        errors.add(:license, 'can\'t be on trial') if license.trial?
        errors.add(:license, 'has no expiration date') unless license.expires_at
      else
        errors.add(:license, 'not found')
      end
    end

    def license
      ::License.current
    end

    def license_key
      license&.data
    end

    def error_response(message)
      ServiceResponse.error(message: message)
    end
  end
end
