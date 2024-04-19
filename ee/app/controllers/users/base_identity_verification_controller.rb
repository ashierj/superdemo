# frozen_string_literal: true

module Users
  class BaseIdentityVerificationController < ApplicationController
    include Arkose::ContentSecurityPolicy
    include Arkose::TokenVerifiable
    include ActionView::Helpers::DateHelper
    include IdentityVerificationHelper
    include ::Gitlab::RackLoadBalancingHelpers
    include Recaptcha::Adapters::ControllerMethods

    EVENT_CATEGORIES = %i[email phone credit_card error toggle_phone_exemption].freeze
    PHONE_VERIFICATION_ACTIONS = %i[send_phone_verification_code verify_phone_verification_code].freeze
    CREDIT_CARD_VERIFICATION_ACTIONS = %i[verify_credit_card].freeze

    before_action :require_verification_user!, except: [:restricted]
    before_action :load_captcha, :redirect_banned_user, only: [:show]
    before_action :ensure_verification_method_attempt_allowed!,
      only: PHONE_VERIFICATION_ACTIONS + CREDIT_CARD_VERIFICATION_ACTIONS

    feature_category :instance_resiliency

    layout 'minimal'

    def show
      push_frontend_feature_flag(:auto_request_phone_number_verification_exemption, @user, type: :gitlab_com_derisk)

      # We need to perform cookie migration for tracking from logged out to log in
      # calling this before tracking gives us access to request where the
      # signed cookie exist with the info we need for migration.
      experiment(:signup_intent_step_one, actor: @user).run
      experiment(:signup_intent_step_one, actor: @user).track(:show, label: :identity_verification)
    end

    def restricted
      render_404
    end

    def verification_state
      Gitlab::PollingInterval.set_header(response, interval: 10_000)

      # if the back button is pressed, don't cache the user's identity verification state
      no_cache_headers if params['no_cache']

      render json: verification_state_json
    end

    def send_phone_verification_code
      unless ensure_challenge_completed(:phone)
        return render status: :bad_request, json: {
          message: s_('IdentityVerification|Complete verification to sign up.')
        }
      end

      result = ::PhoneVerification::Users::SendVerificationCodeService.new(@user, phone_verification_params).execute

      unless result.success?
        log_event(:phone, :failed_attempt, result.reason) unless result.reason == :related_to_high_risk_user

        json_response = { message: result.message, reason: result.reason }

        return render status: :bad_request, json: json_response
      end

      log_event(:phone, :sent_phone_verification_code)

      render json: { status: :success }.merge(result.payload)
    end

    def verify_phone_verification_code
      unless ensure_challenge_completed(:phone)
        return render status: :bad_request, json: {
          message: s_('IdentityVerification|Complete verification to sign up.')
        }
      end

      result = ::PhoneVerification::Users::VerifyCodeService.new(@user, verify_phone_verification_code_params).execute

      unless result.success?
        log_event(:phone, :failed_attempt, result.reason)
        return render status: :bad_request, json: { message: result.message, reason: result.reason }
      end

      log_event(:phone, :success)
      render json: { status: :success }
    end

    def verify_credit_card
      return render_404 unless json_request? && @user.credit_card_validation.present?

      if @user.credit_card_validation.used_by_banned_user?
        ::Users::AutoBanService.new(user: @user, reason: :banned_credit_card).execute

        json_response = { message: user_banned_error_message, reason: :related_to_banned_user }

        log_event(:credit_card, :failed_attempt, :related_to_banned_user)
        render status: :bad_request, json: json_response
      elsif check_for_reuse_rate_limited?
        log_event(:credit_card, :failed_attempt, :rate_limited)
        render status: :bad_request, json: {
          message: rate_limited_error_message(:credit_card_verification_check_for_reuse)
        }
      else
        log_event(:credit_card, :success)
        render json: {}
      end
    end

    def verify_credit_card_captcha
      unless ensure_challenge_completed(:credit_card)
        return render status: :bad_request, json: {
          message: s_('IdentityVerification|Complete verification to sign up.')
        }
      end

      render json: { status: :success }
    end

    def toggle_phone_exemption
      if @user.offer_phone_number_exemption?

        @user.toggle_phone_number_verification

        log_event(:toggle_phone_exemption, :success)
        render json: verification_state_json
      else
        log_event(:toggle_phone_exemption, :failed)
        render status: :bad_request, json: {}
      end
    end

    private

    def require_verification_user!
      @user = find_verification_user || current_user

      return if @user.present?

      redirect_to root_path
    end

    def find_verification_user; end

    def redirect_banned_user
      return unless @user.banned?

      session.delete(:verification_user_id)
      redirect_to new_user_session_path, alert: user_banned_error_message
    end

    def ensure_verification_method_attempt_allowed!
      verification_method_actions = {
        User::VERIFICATION_METHODS[:PHONE_NUMBER] => PHONE_VERIFICATION_ACTIONS,
        User::VERIFICATION_METHODS[:CREDIT_CARD] => CREDIT_CARD_VERIFICATION_ACTIONS
      }

      verification_method, _ = verification_method_actions.find { |_, actions| action_name.to_sym.in?(actions) }
      return if @user.verification_method_allowed?(method: verification_method)

      log_event(verification_method.to_sym, :failed_attempt, :unauthorized)

      render status: :bad_request, json: {}
    end

    def verification_state_json
      {
        verification_methods: @user.required_identity_verification_methods,
        verification_state: @user.identity_verification_state
      }
    end

    def log_event(category, event, reason = nil)
      return unless category.in?(EVENT_CATEGORIES)

      category = "IdentityVerification::#{category.to_s.classify}"
      user = @user || current_user

      Gitlab::AppLogger.info(
        message: category,
        event: event.to_s.titlecase,
        action: action_name,
        username: user&.username,
        ip: request.ip,
        reason: reason.to_s,
        referer: request.referer
      )
      ::Gitlab::Tracking.event(category, event.to_s, property: reason.to_s, user: user)
    end

    def check_for_reuse_rate_limited?
      check_rate_limit!(:credit_card_verification_check_for_reuse, scope: request.ip) { true }
    end

    def phone_verification_params
      required_params.permit(:country, :international_dial_code, :phone_number)
    end

    def verify_phone_verification_code_params
      required_params.permit(:verification_code)
    end

    def load_captcha
      show_recaptcha_challenge? && Gitlab::Recaptcha.load_configurations!
    end

    def ensure_challenge_completed(category)
      # save values in variables before increase in attempts
      recaptcha_shown = show_recaptcha_challenge?
      arkose_shown = show_arkose_challenge?(@user, category)

      # if total daily attempts reach 16K, show reCAPTCHA on every request
      if recaptcha_enabled? && recaptcha_shown
        log_event(:phone, :recaptcha_shown)

        return verify_recaptcha
      end

      # if user makes more than 2 incorrect verification attempts, show arkose challenge
      if enable_arkose_challenge?(category)
        PhoneVerification::Users::RateLimitService.increase_verification_attempts(@user)

        if arkose_shown
          log_event(:phone, :arkose_challenge_shown)

          return verify_arkose_labs_token
        end
      end

      true
    end

    def arkose_labs_enabled?(user: nil)
      ::Arkose::Settings.enabled?(user: user, user_agent: request.user_agent)
    end

    def username
      @user.username
    end
  end
end
