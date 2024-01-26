# frozen_string_literal: true

require 'spec_helper'

RSpec.describe EE::RegistrationsHelper, feature_category: :user_management do
  include Devise::Test::ControllerHelpers
  let(:expected_keys) { UserDetail.registration_objectives.keys - ['joining_team'] }

  describe '#shuffled_registration_objective_options' do
    subject(:shuffled_options) { helper.shuffled_registration_objective_options }

    it 'has values that match all UserDetail registration objective keys' do
      shuffled_option_values = shuffled_options.map { |item| item.last }

      expect(shuffled_option_values).to contain_exactly(*expected_keys)
    end

    it '"other" is always the last option' do
      expect(shuffled_options.last).to eq(['A different reason', 'other'])
    end
  end

  describe '#arkose_labs_data' do
    let(:request_double) { instance_double(ActionDispatch::Request) }
    let(:data_exchange_payload) { 'data_exchange_payload' }

    before do
      allow(helper).to receive(:request).and_return(request_double)

      allow(::Arkose::Settings).to receive(:arkose_public_api_key).and_return('api-key')
      allow(::Arkose::Settings).to receive(:arkose_labs_domain).and_return('domain')

      options = {
        use_case: Arkose::DataExchangePayload::USE_CASE_SIGN_UP,
        require_challenge: false
      }
      allow_next_instance_of(::Arkose::DataExchangePayload, request_double, options) do |instance|
        allow(instance).to receive(:build).and_return(data_exchange_payload)
      end
    end

    subject(:data) { helper.arkose_labs_data }

    it { is_expected.to eq({ api_key: 'api-key', domain: 'domain', data_exchange_payload: data_exchange_payload }) }

    context 'when phone verifications hard limit has been exceeded' do
      before do
        allow(PhoneVerification::Users::RateLimitService)
          .to receive(:daily_transaction_hard_limit_exceeded?).and_return(true)
      end

      it 'builds Arkose data exchange payload with require_challenge option set to true' do
        options = {
          use_case: Arkose::DataExchangePayload::USE_CASE_SIGN_UP,
          require_challenge: true
        }
        expect_next_instance_of(Arkose::DataExchangePayload, request_double, options) do |instance|
          allow(instance).to receive(:build).and_return(data_exchange_payload)
        end

        data
      end
    end

    context 'when arkose_labs_signup_data_exchange feature flag is disabled' do
      before do
        stub_feature_flags(arkose_labs_signup_data_exchange: false)
      end

      it 'does not include data exchange payload' do
        expect(data.keys).not_to include(:data_exchange_payload)
      end
    end

    context 'when data exchange payload is nil' do
      let(:data_exchange_payload) { nil }

      it 'does not include data exchange payload' do
        expect(data.keys).not_to include(:data_exchange_payload)
      end
    end
  end

  describe '#register_omniauth_params' do
    let(:result) do
      {
        glm_source: '_glm_source_',
        glm_content: '_glm_content_'
      }
    end

    before do
      allow(helper)
        .to receive(:glm_tracking_params).and_return({ glm_source: '_glm_source_', glm_content: '_glm_content_' })
    end

    it 'adds intent to register with glm params' do
      expect(helper.register_omniauth_params({})).to eq(result)
    end

    context 'when trial param exists' do
      it 'adds intent to register with glm params and trial' do
        expect(helper.register_omniauth_params({ trial: true })).to eq(result.merge(trial: true))
      end
    end
  end

  describe '#registration_tracking_label' do
    using RSpec::Parameterized::TableSyntax

    where(:trial, :params, :expected_label_symbol) do
      true | {} | :trial
      true | { invite_email: '123@example.com' } | :trial
      false | {} | :free
      false | { invite_email: '123@example.com' } | :invite
    end

    with_them do
      before do
        allow(helper).to receive(:params).and_return(params)
      end

      it 'returns correct tracking label' do
        expect(helper.registration_tracking_label(trial: trial))
          .to eq(::Onboarding::Status::TRACKING_LABEL[expected_label_symbol])
      end
    end
  end
end
