# frozen_string_literal: true

module Onboarding
  class StatusConvertToInviteService
    def initialize(user)
      @user = user
    end

    def execute
      return unless Onboarding.user_onboarding_in_progress?(user)

      if user.update(onboarding_status_registration_type: StatusCreateService::REGISTRATION_TYPE[:invite])
        ServiceResponse.success(payload: payload)
      else
        ServiceResponse.error(message: user.errors.full_messages, payload: payload)
      end
    end

    private

    attr_reader :user, :registration_type

    def payload
      { registration_type: user.onboarding_status_registration_type }
    end
  end
end
