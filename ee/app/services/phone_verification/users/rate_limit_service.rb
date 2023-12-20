# frozen_string_literal: true

# RateLimitService is responsible for keeping track of a user's verification attempts
# during phone verification or the total number of attempts for phone verification in a day
# The controllers/view use this value to determine if a CAPTCHA should be shown to users
# to stop a potential DDoS attack
module PhoneVerification
  module Users
    class RateLimitService
      def self.verification_attempts_limit_exceeded?(user)
        return false unless Feature.enabled?(:arkose_labs_phone_verification_challenge)

        ::Gitlab::ApplicationRateLimiter.peek(:phone_verification_challenge, scope: user)
      end

      def self.increase_verification_attempts(user)
        Feature.enabled?(:arkose_labs_phone_verification_challenge) &&
          ::Gitlab::ApplicationRateLimiter.throttled?(:phone_verification_challenge, scope: user)
      end

      def self.daily_transaction_limit_exceeded?
        return false unless Feature.enabled?(:soft_limit_daily_phone_verifications)

        ::Gitlab::ApplicationRateLimiter.peek(:soft_phone_verification_transactions_limit, scope: nil)
      end

      def self.increase_daily_attempts
        Feature.enabled?(:soft_limit_daily_phone_verifications) &&
          ::Gitlab::ApplicationRateLimiter.throttled?(:soft_phone_verification_transactions_limit, scope: nil)
      end

      def self.assume_user_high_risk_if_daily_limit_exceeded!(user)
        return unless user
        return unless daily_transaction_limit_exceeded?

        user.assume_high_risk(reason: 'Phone verification daily transaction limit exceeded')
      end
    end
  end
end
