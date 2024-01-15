# frozen_string_literal: true

module IdentityVerification
  class UserRiskProfile
    attr_reader :user

    ASSUMED_LOW_RISK_ATTR_KEY = 'assumed_low_risk_reason'
    ASSUMED_HIGH_RISK_ATTR_KEY = 'assumed_high_risk_reason'
    ARKOSE_RISK_BAND_KEY = ::UserCustomAttribute::ARKOSE_RISK_BAND

    def initialize(user)
      @user = user
    end

    def arkose_verified?
      return true if assumed_low_risk?

      arkose_risk_band.in?(::Arkose::VerifyResponse::ARKOSE_RISK_BANDS.map(&:downcase))
    end

    def assume_low_risk!(reason:)
      ::UserCustomAttribute.upsert_custom_attribute(user_id: user.id, key: ASSUMED_LOW_RISK_ATTR_KEY, value: reason)
    end

    def assume_high_risk!(reason:)
      ::UserCustomAttribute.upsert_custom_attribute(user_id: user.id, key: ASSUMED_HIGH_RISK_ATTR_KEY, value: reason)
    end

    def assumed_high_risk?
      user.custom_attributes.by_key(ASSUMED_HIGH_RISK_ATTR_KEY).exists?
    end

    def low_risk?
      arkose_risk_band == ::Arkose::VerifyResponse::RISK_BAND_LOW.downcase
    end

    def medium_risk?
      arkose_risk_band == ::Arkose::VerifyResponse::RISK_BAND_MEDIUM.downcase
    end

    def high_risk?
      arkose_risk_band == ::Arkose::VerifyResponse::RISK_BAND_HIGH.downcase
    end

    private

    def assumed_low_risk?
      user.custom_attributes.by_key(ASSUMED_LOW_RISK_ATTR_KEY).exists?
    end

    def arkose_risk_band
      risk_band_attr = user.custom_attributes.by_key(ARKOSE_RISK_BAND_KEY).first
      return unless risk_band_attr.present?

      risk_band_attr.value.downcase
    end
  end
end
