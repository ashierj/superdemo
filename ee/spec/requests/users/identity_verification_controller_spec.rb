# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Users::IdentityVerificationController, :clean_gitlab_redis_sessions,
  :clean_gitlab_redis_rate_limiting, feature_category: :instance_resiliency do
  include SessionHelpers

  let_it_be(:user) { create(:user, :low_risk) }

  before do
    allow(::Gitlab::ApplicationRateLimiter).to receive(:peek).and_call_original
    allow(::Gitlab::ApplicationRateLimiter).to receive(:throttled?).and_call_original

    allow(user).to receive(:verification_method_allowed?).and_return(true)

    stub_saas_features(identity_verification: true)

    login_as(user)
  end

  shared_examples 'it returns 404 when opt_in_identity_verification feature flag is disabled' do
    before do
      stub_feature_flags(opt_in_identity_verification: false)
    end

    it 'returns 404' do
      do_request

      expect(response).to have_gitlab_http_status(:not_found)
    end
  end

  shared_examples 'it returns 404 when identity_verification saas feature is not available' do
    before do
      stub_saas_features(identity_verification: false)
    end

    it 'returns 404' do
      do_request

      expect(response).to have_gitlab_http_status(:not_found)
    end
  end

  describe 'GET show' do
    subject(:do_request) { get identity_verification_path }

    it_behaves_like 'it requires a signed in user'
    it_behaves_like 'it returns 404 when opt_in_identity_verification feature flag is disabled'
    it_behaves_like 'it returns 404 when identity_verification saas feature is not available'
    it_behaves_like 'it loads reCAPTCHA'

    it 'renders show template with minimal layout' do
      do_request

      expect(response).to render_template('show', layout: 'minimal')
    end
  end

  describe 'GET verification_state' do
    subject(:do_request) { get verification_state_identity_verification_path }

    it_behaves_like 'it requires a signed in user'
    it_behaves_like 'it returns 404 when opt_in_identity_verification feature flag is disabled'
    it_behaves_like 'it sets poll interval header'

    it 'returns verification methods and state' do
      do_request

      expect(json_response).to eq({
        'verification_methods' => ["phone"],
        'verification_state' => { "phone" => false }
      })
    end
  end
end
