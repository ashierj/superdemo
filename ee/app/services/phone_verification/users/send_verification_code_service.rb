# frozen_string_literal: true

module PhoneVerification
  module Users
    class SendVerificationCodeService
      include ActionView::Helpers::DateHelper
      include ::Users::IdentityVerificationHelper
      include Gitlab::Utils::StrongMemoize

      TELESIGN_ERROR = :unknown_telesign_error

      def initialize(user, params = {})
        @user = user
        @params = params

        @record = ::Users::PhoneNumberValidation.for_user(user.id).first_or_initialize
        @record.assign_attributes(params)
      end

      def execute
        return error_in_params unless valid?

        if related_to_banned_user?
          record.save!

          if Feature.enabled?(:identity_verification_auto_ban)
            ::Users::AutoBanService.new(user: user, reason: :banned_phone_number).execute
          end

          return error_related_to_banned_user
        end

        if rate_limited?
          reset_sms_send_data
          return error_rate_limited
        end

        return error_send_not_allowed unless send_allowed?
        return error_high_risk_number if related_to_banned_user?

        risk_result = ::PhoneVerification::TelesignClient::RiskScoreService.new(
          phone_number: phone_number,
          user: user
        ).execute

        return error_downstream_service(risk_result) unless risk_result.success?

        send_code_result = ::PhoneVerification::TelesignClient::SendVerificationCodeService.new(
          phone_number: phone_number,
          user: user
        ).execute

        return error_downstream_service(send_code_result) unless send_code_result.success?

        store_risk_score(risk_result[:risk_score])

        success(risk_result, send_code_result)
      rescue StandardError => e
        Gitlab::ErrorTracking.track_exception(e, user_id: user.id)
        error
      end

      private

      attr_reader :user, :params, :record

      def phone_number
        params[:international_dial_code].to_s + params[:phone_number].to_s
      end

      def valid?
        record.valid?
      end

      def rate_limited?
        ::Gitlab::ApplicationRateLimiter.throttled?(:phone_verification_send_code, scope: user)
      end

      def related_to_banned_user?
        ::Users::PhoneNumberValidation.related_to_banned_user?(
          params[:international_dial_code], params[:phone_number]
        )
      end
      strong_memoize_attr :related_to_banned_user?

      def error_in_params
        ServiceResponse.error(
          message: record.errors.first.full_message,
          reason: :bad_params
        )
      end

      def reset_sms_send_data
        record.update!(sms_send_count: 0, sms_sent_at: nil)
      end

      def error_rate_limited
        interval_in_seconds = ::Gitlab::ApplicationRateLimiter.rate_limits[:phone_verification_send_code][:interval]
        interval = distance_of_time_in_words(interval_in_seconds)

        ServiceResponse.error(
          message: format(
            s_(
              'PhoneVerification|You\'ve reached the maximum number of tries. ' \
              'Wait %{interval} and try again.'
            ),
            interval: interval
          ),
          reason: :rate_limited
        )
      end

      def error_related_to_banned_user
        message = s_(
          'PhoneVerification|There was a problem with the phone number you entered. ' \
          'Enter a different phone number and try again.'
        )

        message = user_banned_error_message if Feature.enabled?(:identity_verification_auto_ban)

        ServiceResponse.error(
          message: message,
          reason: :related_to_banned_user
        )
      end

      def send_allowed?
        sms_send_allowed_after = @record.sms_send_allowed_after
        sms_send_allowed_after ? (Time.current > sms_send_allowed_after) : true
      end

      def error_send_not_allowed
        ServiceResponse.error(message: 'Sending not allowed at this time', reason: :send_not_allowed)
      end

      def error_downstream_service(result)
        force_verify if result.reason == TELESIGN_ERROR

        ServiceResponse.error(
          message: result.message,
          reason: result.reason
        )
      end

      def error
        ServiceResponse.error(
          message: s_('PhoneVerification|Something went wrong. Please try again.'),
          reason: :internal_server_error
        )
      end

      def force_verify
        record.update!(
          risk_score: 0,
          telesign_reference_xid: TELESIGN_ERROR.to_s,
          validated_at: Time.now.utc
        )
      end

      def success(risk_result, send_code_result)
        rate_limit_service = PhoneVerification::Users::RateLimitService
        rate_limit_service.increase_daily_attempts

        if rate_limit_service.daily_transaction_soft_limit_exceeded?
          log_limit_exceeded_event(:soft_phone_verification_transactions_limit)
        end

        if rate_limit_service.daily_transaction_hard_limit_exceeded?
          log_limit_exceeded_event(:hard_phone_verification_transactions_limit)
        end

        last_sms_sent_today = record.sms_sent_at&.today?
        sms_send_count = last_sms_sent_today ? record.sms_send_count + 1 : 1

        attrs = {
          sms_sent_at: Time.current,
          sms_send_count: sms_send_count,
          telesign_reference_xid: send_code_result[:telesign_reference_xid]
        }

        attrs[:risk_score] = risk_result[:risk_score] if Feature.enabled?(:telesign_intelligence, type: :ops)

        record.update!(attrs)

        ServiceResponse.success(payload: { send_allowed_after: record.sms_send_allowed_after })
      end

      def store_risk_score(risk_score)
        return unless Feature.enabled?(:telesign_intelligence, type: :ops)

        Abuse::TrustScoreWorker.perform_async(user.id, :telesign, risk_score.to_f)
      end

      def log_limit_exceeded_event(rate_limit_key)
        ::Gitlab::AppLogger.info(
          class: self.class.name,
          message: 'IdentityVerification::Phone',
          event: 'Phone verification daily transaction limit exceeded',
          exceeded_limit: rate_limit_key.to_s
        )
      end
    end
  end
end
