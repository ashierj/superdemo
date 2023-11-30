# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Users::IdentityVerificationHelper, feature_category: :instance_resiliency do
  using RSpec::Parameterized::TableSyntax

  let_it_be_with_reload(:user) { create(:user) }

  describe '#identity_verification_data' do
    let(:mock_required_identity_verification_methods) { ['email'] }
    let(:mock_offer_phone_number_exemption) { true }

    let(:mock_identity_verification_state) do
      { credit_card: false, email: true }
    end

    before do
      allow(user).to receive(:required_identity_verification_methods).and_return(
        mock_required_identity_verification_methods
      )
      allow(user).to receive(:identity_verification_state).and_return(
        mock_identity_verification_state
      )
      allow(user).to receive(:offer_phone_number_exemption?).and_return(
        mock_offer_phone_number_exemption
      )
      allow(::Arkose::Settings).to receive(:arkose_public_api_key).and_return('api-key')
      allow(::Arkose::Settings).to receive(:arkose_labs_domain).and_return('domain')
      stub_feature_flags(arkose_labs_phone_verification_challenge: false)
    end

    subject(:data) { helper.identity_verification_data(user) }

    context 'when no phone number for user exists' do
      it 'returns the expected data' do
        expect(data[:data]).to eq(expected_data.to_json)
      end
    end

    context 'when phone number for user exists' do
      let_it_be(:phone_number_validation) { create(:phone_number_validation, user: user) }

      it 'returns the expected data' do
        phone_number_data = expected_data[:phone_number].merge({
          country: phone_number_validation.country,
          international_dial_code: phone_number_validation.international_dial_code,
          number: phone_number_validation.phone_number
        })

        expect(data[:data]).to eq(expected_data.merge({ phone_number: phone_number_data }).to_json)
      end
    end

    describe '#rate_limited_error_message' do
      subject(:message) { helper.rate_limited_error_message(limit) }

      let(:limit) { :credit_card_verification_check_for_reuse }

      it 'returns a generic error message' do
        expect(message).to eq(format(s_("IdentityVerification|You've reached the maximum amount of tries. " \
                                        'Wait %{interval} and try again.'), { interval: 'about 1 hour' }))
      end

      context 'when the limit is for email_verification_code_send' do
        let(:limit) { :email_verification_code_send }

        it 'returns a specific message' do
          expect(message).to eq(format(s_("IdentityVerification|You've reached the maximum amount of resends. " \
                                          'Wait %{interval} and try again.'), { interval: 'about 1 hour' }))
        end
      end
    end

    describe '#enable_arkose_challenge' do
      subject(:enable_arkose) { helper.enable_arkose_challenge? }

      before do
        stub_feature_flags(arkose_labs_phone_verification_challenge: feature_flag_enabled)
        allow(helper).to receive(:show_recaptcha_challenge?).and_return(recaptcha_enabled)
      end

      context 'when arkose_labs_phone_verification_challenge feature-flag is disabled' do
        let(:feature_flag_enabled) { false }
        let(:recaptcha_enabled) { false }

        it { is_expected.to be_falsey }
      end

      context 'when arkose_labs_phone_verification_challenge feature-flag is enabled' do
        let(:feature_flag_enabled) { true }

        context 'and reCAPTCHA is disabled' do
          let(:recaptcha_enabled) { false }

          it { is_expected.to be_truthy }
        end

        context 'and reCAPTCHA is enabled' do
          let(:recaptcha_enabled) { true }

          it { is_expected.to be_falsey }
        end
      end
    end

    describe '#show_arkose_challenge' do
      subject(:show_arkose) { helper.show_arkose_challenge?(user) }

      before do
        allow(helper).to receive(:enable_arkose_challenge?).and_return(arkose_enabled)

        allow(PhoneVerification::Users::RateLimitService)
          .to receive(:verification_attempts_limit_exceeded?)
          .with(user)
          .and_return(rate_limit_reached)
      end

      context 'when arkose is not enabled' do
        let(:arkose_enabled) { false }
        let(:rate_limit_reached) { false }

        it { is_expected.to be_falsey }
      end

      context 'when arkose is enabled' do
        let(:arkose_enabled) { true }

        context 'and when verification attempts have not been exceeded' do
          let(:rate_limit_reached) { false }

          it { is_expected.to be_falsey }
        end

        context 'and when verification attempts have been exceeded' do
          let(:rate_limit_reached) { true }

          it { is_expected.to be_truthy }
        end
      end
    end

    describe '#show_recaptcha_challenge' do
      subject(:show_recaptcha) { helper.show_recaptcha_challenge? }

      before do
        allow(Gitlab::Recaptcha).to receive(:enabled?).and_return(recaptcha_enabled)

        allow(PhoneVerification::Users::RateLimitService)
          .to receive(:daily_transaction_limit_exceeded?).and_return(daily_limit_reached)
      end

      context 'when reCAPTCHA is not enabled' do
        let(:recaptcha_enabled) { false }
        let(:daily_limit_reached) { false }

        it { is_expected.to be_falsey }
      end

      context 'when reCAPTCHA is enabled' do
        let(:recaptcha_enabled) { true }

        context 'and daily limit is not reached' do
          let(:daily_limit_reached) { false }

          it { is_expected.to be_falsey }
        end

        context 'and daily limit is reached' do
          let(:daily_limit_reached) { true }

          it { is_expected.to be_truthy }
        end
      end
    end

    private

    def expected_data
      {
        verification_state_path: verification_state_identity_verification_path,
        offer_phone_number_exemption: mock_offer_phone_number_exemption,
        phone_exemption_path: toggle_phone_exemption_identity_verification_path,
        credit_card: {
          user_id: user.id,
          form_id: ::Gitlab::SubscriptionPortal::REGISTRATION_VALIDATION_FORM_ID,
          verify_credit_card_path: verify_credit_card_identity_verification_path
        },
        phone_number: {
          send_code_path: send_phone_verification_code_identity_verification_path,
          verify_code_path: verify_phone_verification_code_identity_verification_path,
          enable_arkose_challenge: 'false',
          show_arkose_challenge: 'false',
          show_recaptcha_challenge: 'false'
        },
        email: {
          obfuscated: helper.obfuscated_email(user.email),
          verify_path: verify_email_code_identity_verification_path,
          resend_path: resend_email_code_identity_verification_path
        },
        arkose: {
          api_key: 'api-key',
          domain: 'domain'
        },
        successful_verification_path: success_identity_verification_path
      }
    end
  end

  describe '#user_banned_error_message' do
    subject(:user_banned_error_message) { helper.user_banned_error_message }

    where(:dot_com, :error_message) do
      true  | "Your account has been blocked. Contact #{EE::CUSTOMER_SUPPORT_URL} for assistance."
      false | "Your account has been blocked. Contact your GitLab administrator for assistance."
    end

    with_them do
      before do
        allow(Gitlab).to receive(:com?).and_return(dot_com)
      end

      it 'returns the correct account banned error message' do
        expect(user_banned_error_message).to eq(error_message)
      end
    end
  end
end
