# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PhoneVerification::Users::RateLimitService, feature_category: :system_access do
  let_it_be(:user) { build(:user) }

  describe '.verification_attempts_limit_exceeded?' do
    subject(:result) { described_class.verification_attempts_limit_exceeded?(user) }

    before do
      allow(Gitlab::ApplicationRateLimiter)
        .to receive(:peek)
        .with(:phone_verification_challenge, scope: user)
        .and_return(exceeded)
    end

    context 'when limit has been exceeded' do
      let(:exceeded) { true }

      it { is_expected.to eq true }
    end

    context 'when limit has not been exceeded' do
      let(:exceeded) { false }

      it { is_expected.to eq false }
    end

    context 'when arkose_labs_phone_verification_challenge is disabled' do
      let(:exceeded) { true }

      before do
        stub_feature_flags(arkose_labs_phone_verification_challenge: false)
      end

      it 'returns false', :aggregate_failures do
        expect(Gitlab::ApplicationRateLimiter).not_to receive(:peek)
        expect(result).to eq false
      end
    end
  end

  describe '.increase_verification_attempts' do
    subject(:increase_attempts) { described_class.increase_verification_attempts(user) }

    it 'calls throttled?' do
      expect(::Gitlab::ApplicationRateLimiter)
        .to receive(:throttled?)
        .with(:phone_verification_challenge, scope: user)

      increase_attempts
    end

    context 'when arkose_labs_phone_verification_challenge is disabled' do
      before do
        stub_feature_flags(arkose_labs_phone_verification_challenge: false)
      end

      it 'does not call throttled?', :aggregate_failures do
        expect(Gitlab::ApplicationRateLimiter).not_to receive(:throttled?)

        increase_attempts
      end
    end
  end

  describe '.daily_transaction_limit_exceeded?' do
    subject(:result) { described_class.daily_transaction_limit_exceeded? }

    before do
      allow(Gitlab::ApplicationRateLimiter)
        .to receive(:peek)
        .with(:soft_phone_verification_transactions_limit, scope: nil)
        .and_return(exceeded)
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

      it 'returns false' do
        expect(Gitlab::ApplicationRateLimiter).not_to receive(:peek)
        expect(result).to eq false
      end
    end
  end

  describe '.increase_daily_attempts' do
    subject(:increase_attempts) { described_class.increase_daily_attempts }

    it 'calls throttled?' do
      expect(::Gitlab::ApplicationRateLimiter)
        .to receive(:throttled?)
        .with(:soft_phone_verification_transactions_limit, scope: nil)

      increase_attempts
    end

    context 'when soft_limit_daily_phone_verifications is disabled' do
      before do
        stub_feature_flags(soft_limit_daily_phone_verifications: false)
      end

      it 'does not call throttled?' do
        expect(Gitlab::ApplicationRateLimiter).not_to receive(:throttled?)

        increase_attempts
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

    context 'when limit has not been exceeded' do
      let(:limit_exceeded) { false }

      it 'does not call assume_high_risk on the user' do
        expect(user).not_to receive(:assume_high_risk)

        call_method
      end
    end
  end
end
