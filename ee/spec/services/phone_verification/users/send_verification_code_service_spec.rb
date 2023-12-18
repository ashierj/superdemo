# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PhoneVerification::Users::SendVerificationCodeService, feature_category: :system_access do
  using RSpec::Parameterized::TableSyntax

  let_it_be_with_reload(:user) { create(:user) }
  let(:params) { { country: 'US', international_dial_code: 1, phone_number: '555' } }

  subject(:service) { described_class.new(user, params) }

  describe '#execute' do
    before do
      allow(Gitlab::ApplicationRateLimiter)
        .to receive(:peek).with(:soft_phone_verification_transactions_limit, scope: nil).and_return(false)
      allow(Gitlab::ApplicationRateLimiter)
        .to receive(:throttled?).with(:soft_phone_verification_transactions_limit, scope: nil).and_return(false)

      allow_next_instance_of(PhoneVerification::TelesignClient::RiskScoreService) do |instance|
        allow(instance).to receive(:execute).and_return(risk_service_response)
      end

      allow_next_instance_of(PhoneVerification::TelesignClient::SendVerificationCodeService) do |instance|
        allow(instance).to receive(:execute).and_return(send_verification_code_response)
      end

      allow(Gitlab::ApplicationRateLimiter).to receive(:throttled?)
        .with(:phone_verification_send_code, scope: user).and_return(false)
    end

    context 'when params are invalid' do
      let(:params) { { country: 'US', international_dial_code: 1 } }

      it 'returns an error', :aggregate_failures do
        response = service.execute

        expect(response).to be_a(ServiceResponse)
        expect(response).to be_error
        expect(response.message).to eq('Phone number can\'t be blank')
        expect(response.reason).to eq(:bad_params)
      end
    end

    context 'when user has reached max verification attempts' do
      let(:record) { create(:phone_number_validation, user: user) }

      before do
        allow(Gitlab::ApplicationRateLimiter).to receive(:throttled?)
        .with(:phone_verification_send_code, scope: user).and_return(true)
      end

      it 'returns an error', :aggregate_failures do
        response = service.execute

        expect(response).to be_a(ServiceResponse)
        expect(response).to be_error
        expect(response.message).to eq(
          'You\'ve reached the maximum number of tries. ' \
          'Wait 1 day and try again.'
        )
        expect(response.reason).to eq(:rate_limited)
      end
    end

    context 'when phone number is linked to an already banned user' do
      let(:banned_user) { create(:user, :banned) }
      let(:record) { create(:phone_number_validation, :validated, user: banned_user) }

      let(:params) do
        {
          country: 'AU',
          international_dial_code: record.international_dial_code,
          phone_number: record.phone_number
        }
      end

      where(:dot_com, :error_message) do
        true  | "Your account has been blocked. Contact #{EE::CUSTOMER_SUPPORT_URL} for assistance."
        false | "Your account has been blocked. Contact your GitLab administrator for assistance."
      end

      with_them do
        before do
          allow(Gitlab).to receive(:com?).and_return(dot_com)
        end

        it 'bans the user' do
          expect_next_instance_of(::Users::AutoBanService, user: user, reason: :banned_phone_number) do |instance|
            expect(instance).to receive(:execute).and_call_original
          end

          service.execute

          expect(user).to be_banned
        end

        it 'returns an error', :aggregate_failures do
          response = service.execute

          expect(response).to be_a(ServiceResponse)
          expect(response).to be_error
          expect(response.message).to eq(error_message)
          expect(response.reason).to eq(:related_to_banned_user)
        end
      end

      context 'when the `identity_verification_auto_ban` feature flag is disabled' do
        before do
          stub_feature_flags(identity_verification_auto_ban: false)
        end

        it 'does not ban the user' do
          service.execute

          expect(user).not_to be_banned
        end

        it 'returns an error', :aggregate_failures do
          response = service.execute

          expect(response).to be_a(ServiceResponse)
          expect(response).to be_error
          expect(response.message).to eq(s_(
            'PhoneVerification|There was a problem with the phone number you entered. '\
            'Enter a different phone number and try again.'))
          expect(response.reason).to eq(:related_to_banned_user)
        end
      end
    end

    context 'when phone number is high risk' do
      let_it_be(:risk_service_response) do
        ServiceResponse.error(message: 'Downstream error message', reason: :invalid_phone_number)
      end

      it 'returns an error', :aggregate_failures do
        response = service.execute

        expect(response).to be_a(ServiceResponse)
        expect(response).to be_error
        expect(response.message).to eq('Downstream error message')
        expect(response.reason).to eq(:invalid_phone_number)
      end
    end

    context 'when there is a client error in sending the verification code' do
      let_it_be(:risk_service_response) { ServiceResponse.success }

      let_it_be(:send_verification_code_response) do
        ServiceResponse.error(message: 'Downstream error message', reason: :bad_request)
      end

      it 'returns an error', :aggregate_failures do
        response = service.execute

        expect(response).to be_a(ServiceResponse)
        expect(response).to be_error
        expect(response.message).to eq('Downstream error message')
        expect(response.reason).to eq(:bad_request)
      end
    end

    context 'when there is a TeleSign error in getting the risk score' do
      let_it_be(:risk_service_response) do
        ServiceResponse.error(message: 'Downstream error message', reason: :unknown_telesign_error)
      end

      it 'returns an error', :aggregate_failures do
        response = service.execute

        expect(response).to be_a(ServiceResponse)
        expect(response).to be_error
        expect(response.message).to eq('Downstream error message')
        expect(response.reason).to eq(:unknown_telesign_error)
      end

      it 'force verifies the user', :aggregate_failures, :freeze_time do
        service.execute
        record = user.phone_number_validation

        expect(record.validated_at).to eq(Time.now.utc)
        expect(record.risk_score).to eq(0)
        expect(record.telesign_reference_xid).to eq('unknown_telesign_error')
      end
    end

    context 'when there is a TeleSign error in sending the verification code' do
      let_it_be(:risk_service_response) { ServiceResponse.success }

      let_it_be(:send_verification_code_response) do
        ServiceResponse.error(message: 'Downstream error message', reason: :unknown_telesign_error)
      end

      it 'returns an error', :aggregate_failures do
        response = service.execute

        expect(response).to be_a(ServiceResponse)
        expect(response).to be_error
        expect(response.message).to eq('Downstream error message')
        expect(response.reason).to eq(:unknown_telesign_error)
      end

      it 'force verifies the user', :aggregate_failures, :freeze_time do
        service.execute
        record = user.phone_number_validation

        expect(record.validated_at).to eq(Time.now.utc)
        expect(record.risk_score).to eq(0)
        expect(record.telesign_reference_xid).to eq('unknown_telesign_error')
      end
    end

    context 'when there is a server error in sending the verification code' do
      let_it_be(:risk_service_response) { ServiceResponse.success }

      let_it_be(:send_verification_code_response) do
        ServiceResponse.error(message: 'Downstream error message', reason: :internal_server_error)
      end

      it 'returns an error', :aggregate_failures do
        response = service.execute

        expect(response).to be_a(ServiceResponse)
        expect(response).to be_error
        expect(response.message).to eq('Downstream error message')
        expect(response.reason).to eq(:internal_server_error)
      end
    end

    context 'when there is an unknown exception' do
      let(:exception) { StandardError.new }

      before do
        allow(Gitlab::ErrorTracking).to receive(:track_exception)
        allow_next_instance_of(PhoneVerification::TelesignClient::RiskScoreService) do |instance|
          allow(instance).to receive(:execute).and_raise(exception)
        end
      end

      it 'returns an error ServiceResponse', :aggregate_failures do
        response = service.execute

        expect(response).to be_a(ServiceResponse)
        expect(response).to be_error
        expect(response.message).to eq('Something went wrong. Please try again.')
        expect(response.reason).to be(:internal_server_error)
      end

      it 'tracks the exception' do
        service.execute

        expect(Gitlab::ErrorTracking).to have_received(:track_exception).with(
          exception, user_id: user.id
        )
      end
    end

    context 'when verification code is sent successfully' do
      let_it_be(:risk_score) { 10 }
      let_it_be(:telesign_reference_xid) { '123' }
      let_it_be(:user_scores) { Abuse::UserTrustScore.new(user) }

      let_it_be(:risk_service_response) do
        ServiceResponse.success(payload: { risk_score: risk_score })
      end

      let_it_be(:send_verification_code_response) do
        ServiceResponse.success(payload: { telesign_reference_xid: telesign_reference_xid })
      end

      it 'increments soft_phone_verification_transactions_limit rate limit count' do
        expect(Gitlab::ApplicationRateLimiter)
          .to receive(:throttled?).with(:soft_phone_verification_transactions_limit, scope: nil).and_return(false)

        service.execute
      end

      context 'when soft_phone_verification_transactions_limit rate limit is hit' do
        it 'logs the event' do
          allow(Gitlab::ApplicationRateLimiter)
            .to receive(:throttled?).with(:soft_phone_verification_transactions_limit, scope: nil).and_return(true)

          expect(Gitlab::AppLogger).to receive(:info).with({
            class: described_class.name,
            message: 'IdentityVerification::Phone',
            event: 'Phone verification daily transaction limit exceeded'
          })

          service.execute
        end

        context 'when soft_limit_daily_phone_verifications is disabled' do
          before do
            stub_feature_flags(soft_limit_daily_phone_verifications: false)
          end

          it 'does not increment soft_phone_verification_transactions_limit rate limit count' do
            expect(Gitlab::ApplicationRateLimiter)
              .not_to receive(:throttled?).with(:soft_phone_verification_transactions_limit, scope: nil)

            service.execute
          end

          it 'does not log', :aggregate_failures do
            expect(Gitlab::ApplicationRateLimiter)
              .not_to receive(:throttled?).with(:soft_phone_verification_transactions_limit)
            expect(Gitlab::AppLogger).not_to receive(:info)

            service.execute
          end
        end
      end

      it 'returns a success response', :aggregate_failures do
        response = service.execute

        expect(response).to be_a(ServiceResponse)
        expect(response).to be_success
      end

      it 'saves the risk score, telesign_reference_xid and increases verification attempts', :aggregate_failures do
        service.execute
        record = user.phone_number_validation

        expect(record.risk_score).to eq(risk_score)
        expect(record.telesign_reference_xid).to eq(telesign_reference_xid)
      end

      it 'stores risk score in abuse trust scores' do
        service.execute

        expect(user_scores.telesign_score).to eq(risk_score.to_f)
      end
    end

    context 'when telesign_intelligence feature flag is disabled' do
      let_it_be(:risk_service_response) do
        ServiceResponse.success(payload: { risk_score: 1 })
      end

      let_it_be(:send_verification_code_response) do
        ServiceResponse.success(payload: { telesign_reference_xid: '123' })
      end

      before do
        stub_feature_flags(telesign_intelligence: false)
      end

      it 'returns a success response', :aggregate_failures do
        response = service.execute

        expect(response).to be_a(ServiceResponse)
        expect(response).to be_success
      end

      it 'does not save the risk_score' do
        service.execute
        record = user.phone_number_validation

        expect(record.risk_score).to eq 0
        expect(record.telesign_reference_xid).to eq '123'
      end

      it 'does not store risk score in abuse trust scores' do
        expect { service.execute }.not_to change { Abuse::TrustScore.count }
      end
    end
  end

  describe '.assume_user_high_risk_if_daily_limit_exceeded!' do
    let(:limit_exceeded) { true }

    subject(:call_method) { described_class.assume_user_high_risk_if_daily_limit_exceeded!(user) }

    before do
      allow(described_class).to receive(:daily_transaction_limit_exceeded?).and_return(limit_exceeded)
    end

    it 'calls assume_high_risk on the user' do
      expect(user).to receive(:assume_high_risk).with(reason: 'Phone verification daily transaction limit exceeded')

      call_method
    end

    shared_examples 'it does nothing' do
      it 'does nothing' do
        expect(user).not_to receive(:assume_high_risk)

        call_method
      end
    end

    context 'when no user is passed' do
      let(:user) { nil }

      it_behaves_like 'it does nothing'
    end

    context 'when limit has not been exceeded' do
      let(:limit_exceeded) { false }

      it_behaves_like 'it does nothing'
    end
  end

  describe '.daily_transaction_limit_exceeded?' do
    subject(:result) { described_class.daily_transaction_limit_exceeded? }

    before do
      allow(Gitlab::ApplicationRateLimiter)
        .to receive(:peek).with(:soft_phone_verification_transactions_limit, scope: nil).and_return(exceeded)
    end

    context 'when limit has been exceeded' do
      let(:exceeded) { true }

      it { is_expected.to eq true }
    end

    context 'when limit has not been exceeded' do
      let(:exceeded) { false }

      it { is_expected.to eq false }
    end

    context 'when soft_limit_daily_phone_verifications is disabled' do
      let(:exceeded) { true }

      before do
        stub_feature_flags(soft_limit_daily_phone_verifications: false)
      end

      it 'returns false', :aggregate_failures do
        expect(Gitlab::ApplicationRateLimiter).not_to receive(:peek)
        expect(result).to eq false
      end
    end
  end
end
