# frozen_string_literal: true

module EE
  module PersonalAccessTokens
    module RotateService
      extend ::Gitlab::Utils::Override

      private

      override :expires_at
      def expires_at(params)
        expires_at = super
        max_pat_lifetime_duration = ::Gitlab::CurrentSettings.max_personal_access_token_lifetime_from_now

        return max_pat_lifetime_duration if max_pat_lifetime_duration && max_pat_lifetime_duration < expires_at

        expires_at
      end
    end
  end
end
