# frozen_string_literal: true

RSpec.shared_examples 'it requires a signed in user' do
  let_it_be(:confirmed_user) { create(:user) }

  before do
    stub_session(session_data: { verification_user_id: nil })
    sign_in confirmed_user

    do_request
  end

  it 'sets the user instance variable' do
    expect(assigns(:user)).to eq(confirmed_user)
  end

  it 'does not redirect to root path' do
    expect(response).not_to redirect_to(root_path)
  end
end

RSpec.shared_examples 'it loads reCAPTCHA' do
  before do
    stub_feature_flags(arkose_labs_phone_verification_challenge: false)
  end

  context 'when reCAPTCHA is disabled' do
    before do
      allow(Gitlab::Recaptcha).to receive(:enabled?).and_return(false)
    end

    it 'does not load recaptcha configuration' do
      expect(Gitlab::Recaptcha).not_to receive(:load_configurations!)

      do_request
    end
  end

  context 'when reCAPTCHA is enabled but daily limit has not been exceeded' do
    before do
      allow(Gitlab::Recaptcha).to receive(:enabled?).and_return(true)
      allow(::Gitlab::ApplicationRateLimiter)
        .to receive(:peek)
        .with(:soft_phone_verification_transactions_limit, scope: nil)
        .and_return(false)
    end

    it 'does not load reCAPTCHA configuration' do
      expect(Gitlab::Recaptcha).not_to receive(:load_configurations!)

      do_request
    end
  end

  context 'when reCAPTCHA is enabled and daily limit has been exceeded' do
    before do
      allow(Gitlab::Recaptcha).to receive(:enabled?).and_return(true)
      allow(::Gitlab::ApplicationRateLimiter)
        .to receive(:peek)
        .with(:soft_phone_verification_transactions_limit, scope: nil)
        .and_return(true)
    end

    it 'loads reCAPTCHA configuration' do
      expect(Gitlab::Recaptcha).to receive(:load_configurations!)

      do_request
    end
  end
end

# GET verification_state
RSpec.shared_examples 'it sets poll interval header' do
  it 'sets poll interval header' do
    do_request

    expect(response.headers.to_h).to include(Gitlab::PollingInterval::HEADER_NAME => '10000')
  end
end
