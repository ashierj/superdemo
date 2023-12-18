# frozen_string_literal: true

module Users
  class IdentityVerificationController < ApplicationController
    include AcceptsPendingInvitations
    include ActionView::Helpers::DateHelper
    include Arkose::ContentSecurityPolicy
    include IdentityVerificationHelper
    include ::Gitlab::RackLoadBalancingHelpers

    EVENT_CATEGORIES = %i[email phone credit_card error toggle_phone_exemption].freeze
    PHONE_VERIFICATION_ACTIONS = %i[send_phone_verification_code verify_phone_verification_code].freeze
    CREDIT_CARD_VERIFICATION_ACTIONS = %i[verify_credit_card].freeze

    skip_before_action :authenticate_user!

    before_action :require_verification_user!
    before_action :require_unverified_user!, except: [:verification_state, :success]
    before_action :redirect_banned_user, only: [:show]
    before_action :require_arkose_verification!, except: [:arkose_labs_challenge, :verify_arkose_labs_session]
    before_action :ensure_verification_method_attempt_allowed!,
      only: PHONE_VERIFICATION_ACTIONS + CREDIT_CARD_VERIFICATION_ACTIONS
    before_action :verify_arkose_labs_session_for_phone_verification, only: PHONE_VERIFICATION_ACTIONS

    before_action only: :show do
      push_frontend_feature_flag(:arkose_labs_phone_verification_challenge)
    end

    feature_category :instance_resiliency

    layout 'minimal'

    def show
      # We to perform cookie migration for tracking from logged out to log in
      # calling this before tracking gives us access to request where the
      # signed cookie exist with the info we need for migration.
      experiment(:free_trial_registration_redesign, actor: @user).run
      experiment(:free_trial_registration_redesign, actor: @user).track(:show, label: 'identity_verification')
    end

    def verification_state
      # if the back button is pressed, don't cache the user's identity verification state
      no_cache_headers

      render json: {
        verification_methods: @user.required_identity_verification_methods,
        verification_state: @user.identity_verification_state
      }
    end

    def verify_email_code
      result = verify_token

      if result[:status] == :success
        confirm_user

        render json: { status: :success }
      else
        log_event(:email, :failed_attempt, result[:reason])

        render json: result
      end
    end

    def resend_email_code
      if send_rate_limited?
        render json: { status: :failure, message: rate_limited_error_message(:email_verification_code_send) }
      else
        reset_confirmation_token

        render json: { status: :success }
      end
    end

    def send_phone_verification_code
      result = ::PhoneVerification::Users::SendVerificationCodeService.new(@user, phone_verification_params).execute

      unless result.success?
        log_event(:phone, :failed_attempt, result.reason)

        # Do not pass the `related_to_banned_user` reason to the frontend if the `identity_verification_auto_ban`
        # feature flag is disabled, to allow re-submitting the form.
        json_response = if Feature.disabled?(:identity_verification_auto_ban) &&
            result.reason == :related_to_banned_user
                          { message: result.message }
                        else
                          { message: result.message, reason: result.reason }
                        end

        return render status: :bad_request, json: json_response
      end

      log_event(:phone, :sent_phone_verification_code)
      render json: { status: :success }
    end

    def verify_phone_verification_code
      result = ::PhoneVerification::Users::VerifyCodeService.new(@user, verify_phone_verification_code_params).execute

      unless result.success?
        log_event(:phone, :failed_attempt, result.reason)
        return render status: :bad_request, json: { message: result.message, reason: result.reason }
      end

      log_event(:phone, :success)
      render json: { status: :success }
    end

    def verify_arkose_labs_session_for_phone_verification
      return unless Feature.enabled?(:arkose_labs_phone_verification_challenge)

      # it's a soft rate-limit so we will show the user captcha in the front-end, but not block the request
      challenged = ::Gitlab::ApplicationRateLimiter.throttled?(:phone_verification_challenge, scope: @user)

      return unless challenged

      log_event(:phone, :verification_challenge_triggered)

      return if verify_arkose_labs_token(save_user_data: false)

      render status: :bad_request, json: {
        message: s_('IdentityVerification|Complete verification to sign up.')
      }
    end

    def arkose_labs_challenge; end

    def verify_arkose_labs_session
      unless verify_arkose_labs_token
        flash[:alert] = s_('IdentityVerification|Complete verification to sign up.')
        return render action: :arkose_labs_challenge
      end

      service = PhoneVerification::Users::SendVerificationCodeService
      service.assume_user_high_risk_if_daily_limit_exceeded!(@user)

      redirect_to action: :show
    end

    def success
      return redirect_to identity_verification_path unless @user.identity_verified?

      accept_pending_invitations(user: @user)
      sign_in(@user)
      session.delete(:verification_user_id)
      set_redirect_url
      experiment(:phone_verification_for_low_risk_users, user: @user).track(:registration_completed)

      render 'devise/sessions/successful_verification'
    end

    def verify_credit_card
      return render_404 unless json_request? && @user.credit_card_validation.present?

      if @user.credit_card_validation.used_by_banned_user?
        json_response =
          if Feature.enabled?(:identity_verification_auto_ban)
            ::Users::AutoBanService.new(user: @user, reason: :banned_credit_card).execute
            { message: user_banned_error_message, reason: :related_to_banned_user }
          else
            { message: s_('IdentityVerification|There was a problem with the credit card details you ' \
                          'entered. Use a different credit card and try again.') }
          end

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

    def toggle_phone_exemption
      if @user.offer_phone_number_exemption?
        @user.toggle_phone_number_verification

        log_event(:toggle_phone_exemption, :success)
        render json: {
          verification_methods: @user.required_identity_verification_methods,
          verification_state: @user.identity_verification_state
        }
      else
        log_event(:toggle_phone_exemption, :failed)
        render status: :bad_request, json: {}
      end
    end

    private

    def set_redirect_url
      onboarding_status = ::Onboarding::Status.new(params.to_unsafe_h.deep_symbolize_keys, session, @user)
      @redirect_url = if onboarding_status.subscription?
                        # Since we need this value to stay in the stored_location_for(user) in order for
                        # us to be properly redirected for subscription signups.
                        onboarding_status.stored_user_location
                      else
                        after_sign_in_path_for(@user)
                      end
    end

    def require_verification_user!
      @user = find_verification_user || current_user

      return if @user.present?

      redirect_to root_path
    end

    def find_verification_user
      return unless session[:verification_user_id]

      verification_user_id = session[:verification_user_id]
      load_balancer_stick_request(::User, :user, verification_user_id)
      User.find_by_id(verification_user_id)
    end

    def require_unverified_user!
      redirect_to success_identity_verification_path if @user.identity_verified?
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

    def redirect_banned_user
      return unless @user.banned?

      session.delete(:verification_user_id)
      redirect_to new_user_session_path, alert: user_banned_error_message
    end

    def require_arkose_verification!
      return unless Feature.enabled?(:arkose_labs_oauth_signup_challenge)
      return unless ::Arkose::Settings.enabled?(user: @user, user_agent: request.user_agent)
      return unless @user.identities.any?
      return unless @user.arkose_risk_band.blank?

      redirect_to action: :arkose_labs_challenge
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

    def verify_token
      ::Users::EmailVerification::ValidateTokenService.new(
        attr: :confirmation_token,
        user: @user,
        token: params.require(:identity_verification).permit(:code)[:code]
      ).execute
    end

    def confirm_user
      @user.confirm
      log_event(:email, :success)
    end

    def reset_confirmation_token
      service = ::Users::EmailVerification::GenerateTokenService.new(attr: :confirmation_token, user: @user)
      token, encrypted_token = service.execute
      @user.update!(confirmation_token: encrypted_token, confirmation_sent_at: Time.current)
      Notify.confirmation_instructions_email(@user.email, token: token).deliver_later
      log_event(:email, :sent_instructions)
    end

    def send_rate_limited?
      ::Gitlab::ApplicationRateLimiter.throttled?(:email_verification_code_send, scope: @user)
    end

    def check_for_reuse_rate_limited?
      check_rate_limit!(:credit_card_verification_check_for_reuse, scope: request.ip) { true }
    end

    def phone_verification_params
      params.require(:identity_verification).permit(:country, :international_dial_code, :phone_number)
    end

    def verify_phone_verification_code_params
      params.require(:identity_verification).permit(:verification_code)
    end

    def verify_arkose_labs_token(save_user_data: true)
      return false unless params[:arkose_labs_token].present?

      user = @user if save_user_data

      result = Arkose::TokenVerificationService.new(session_token: params[:arkose_labs_token], user: user).execute
      result.success?
    end
  end
end
