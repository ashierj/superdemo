# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PhoneVerification::Users::SendVerificationCodeService, feature_category: :instance_resiliency do
  using RSpec::Parameterized::TableSyntax

  let_it_be_with_reload(:user) { create(:user) }
  let(:params) { { country: 'US', international_dial_code: 1, phone_number: '555' } }

  subject(:service) { described_class.new(user, params) }

  describe '#execute' do
    before do
      allow(Gitlab::ApplicationRateLimiter).to receive(:throttled?)
        .with(:phone_verification_send_code, scope: user).and_return(false)

      %i[soft hard].each do |prefix|
        rate_limit_name = "#{prefix}_phone_verification_transactions_limit".to_sym
        allow(Gitlab::ApplicationRateLimiter)
          .to receive(:peek).with(rate_limit_name, scope: nil).and_return(false)
        allow(Gitlab::ApplicationRateLimiter)
          .to receive(:throttled?).with(rate_limit_name, scope: nil).and_return(false)
      end

      allow_next_instance_of(PhoneVerification::TelesignClient::RiskScoreService) do |instance|
        allow(instance).to receive(:execute).and_return(risk_service_response)
      end

      allow_next_instance_of(PhoneVerification::TelesignClient::SendVerificationCodeService) do |instance|
        allow(instance).to receive(:execute).and_return(send_verification_code_response)
      end
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
      let_it_be(:record) { create(:phone_number_validation, sms_send_count: 1, sms_sent_at: Time.current, user: user) }

      before do
        allow(Gitlab::ApplicationRateLimiter).to receive(:throttled?)
        .with(:phone_verification_send_code, scope: user).and_return(true)
      end

      it 'resets sms_send_count and sms_sent_at' do
        expect { service.execute }.to change { [record.reload.sms_send_count, record.reload.sms_sent_at] }.to([0, nil])
      end

      context 'when sms_send_wait_time feature flag is disabled' do
        before do
          stub_feature_flags(sms_send_wait_time: false)
        end

        it 'does not reset sms_send_count and sms_sent_at' do
          expect { service.execute }.not_to change { [record.reload.sms_send_count, record.reload.sms_sent_at] }
        end
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

        it 'saves the phone number validation record' do
          service.execute

          record = user.phone_number_validation

          expect(record.international_dial_code).to eq(params[:international_dial_code])
          expect(record.phone_number).to eq(params[:phone_number])
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

        it 'saves the phone number validation record' do
          service.execute

          record = user.phone_number_validation

          expect(record.international_dial_code).to eq(params[:international_dial_code])
          expect(record.phone_number).to eq(params[:phone_number])
        end

        it 'returns an error', :aggregate_failures do
          response = service.execute

          expect(response).to be_a(ServiceResponse)
          expect(response).to be_error
          expect(response.message).to eq(s_(
            'PhoneVerification|There was a problem with the phone number you entered. ' \
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

    shared_examples 'it returns a success response' do
      it 'returns a success response', :aggregate_failures do
        response = service.execute

        expect(response).to be_a(ServiceResponse)
        expect(response).to be_success
      end
    end

    context 'when verification code is sent successfully' do
      let_it_be(:risk_score) { 10 }
      let_it_be(:telesign_reference_xid) { '123' }

      let_it_be(:risk_service_response) do
        ServiceResponse.success(payload: { risk_score: risk_score })
      end

      let_it_be(:send_verification_code_response) do
        ServiceResponse.success(payload: { telesign_reference_xid: telesign_reference_xid })
      end

      it 'increments phone verification transactions count' do
        expect(PhoneVerification::Users::RateLimitService).to receive(:increase_daily_attempts)

        service.execute
      end

      context 'when limit is hit' do
        where(:limit, :rate_limit_key) do
          'soft' | :soft_phone_verification_transactions_limit
          'hard' | :hard_phone_verification_transactions_limit
        end

        with_them do
          before do
            allow(Gitlab::ApplicationRateLimiter).to receive(:peek).with(rate_limit_key, scope: nil).and_return(true)
          end

          it 'logs the event' do
            expect(Gitlab::AppLogger).to receive(:info).with({
              class: described_class.name,
              message: 'IdentityVerification::Phone',
              event: 'Phone verification daily transaction limit exceeded',
              exceeded_limit: rate_limit_key.to_s
            })

            service.execute
          end
        end
      end

      it_behaves_like 'it returns a success response'

      it 'saves the risk score and telesign_reference_xid', :aggregate_failures do
        service.execute
        record = user.phone_number_validation

        expect(record.risk_score).to eq(risk_score)
        expect(record.telesign_reference_xid).to eq(telesign_reference_xid)
      end

      it 'executes the abuse trust score worker' do
        expect(Abuse::TrustScoreWorker).to receive(:perform_async).once.with(user.id, :telesign, instance_of(Float))

        service.execute
      end

      it 'updates sms_send_count and sms_sent_at', :freeze_time do
        service.execute
        record = user.phone_number_validation
        expect(record.sms_send_count).to eq(1)
        expect(record.sms_sent_at).to eq(Time.current)
      end

      context 'when last SMS was sent before the current day' do
        before do
          create(:phone_number_validation, user: user, sms_sent_at: 1.day.ago, sms_send_count: 2)
        end

        it 'sets sms_send_count to 1' do
          record = user.phone_number_validation
          expect { service.execute }.to change { record.reload.sms_send_count }.from(2).to(1)
        end
      end

      context 'when sms_send_wait_time feature flag is disabled' do
        before do
          stub_feature_flags(sms_send_wait_time: false)
        end

        it 'does not update sms_send_count and sms_sent_at', :freeze_time, :aggregate_failures do
          service.execute
          record = user.phone_number_validation
          expect(record.sms_send_count).to eq(0)
          expect(record.sms_sent_at).to be_nil
        end
      end

      context 'when send is allowed', :freeze_time do
        let_it_be(:record) do
          create(:phone_number_validation, user: user, sms_send_count: 1, sms_sent_at: Time.current)
        end

        let!(:old_sms_sent_at) { record.sms_sent_at }

        before do
          travel_to(5.minutes.from_now)
        end

        it_behaves_like 'it returns a success response'

        it 'increments sms_send_count and sets sms_sent_at', :aggregate_failures do
          expect(record.sms_send_count).to eq 1
          expect(record.sms_sent_at).to be_within(1.second).of(old_sms_sent_at)

          service.execute
          record.reload

          expect(record.sms_send_count).to eq 2
          expect(record.sms_sent_at).to be_within(1.second).of(old_sms_sent_at + 5.minutes)
        end
      end

      context 'when send is not allowed', :freeze_time do
        let_it_be(:record) do
          create(:phone_number_validation, user: user, sms_send_count: 1, sms_sent_at: Time.current)
        end

        it 'returns an error', :aggregate_failures do
          response = service.execute

          expect(response).to be_a(ServiceResponse)
          expect(response).to be_error
          expect(response.message).to eq('Sending not allowed at this time')
          expect(response.reason).to eq(:send_not_allowed)
        end
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

      it_behaves_like 'it returns a success response'

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
end
