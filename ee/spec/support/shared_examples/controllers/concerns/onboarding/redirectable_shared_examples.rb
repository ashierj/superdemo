# frozen_string_literal: true

RSpec.shared_examples EE::Onboarding::Redirectable do |registration_type|
  context 'when onboarding is enabled' do
    let(:params) { glm_params.merge(bogus: '_bogus_') } # used in calling specs sometimes

    before do
      stub_saas_features(onboarding: true)
    end

    it 'onboards the user' do
      post_create

      expect(response).to redirect_to(users_sign_up_welcome_path(redirect_params))
      created_user = User.find_by_email(new_user_email)
      expect(created_user).to be_onboarding_in_progress
      expect(created_user.onboarding_status_step_url).to eq(users_sign_up_welcome_path(redirect_params))
      expect(created_user.onboarding_status_initial_registration_type).to eq(registration_type)
      expect(created_user.onboarding_status_registration_type).to eq(registration_type)
    end
  end

  context 'when onboarding is disabled' do
    before do
      stub_saas_features(onboarding: false)
    end

    it 'does not onboard the user' do
      post_create

      expect(response).not_to redirect_to(users_sign_up_welcome_path(redirect_params))
      created_user = User.find_by_email(new_user_email)
      expect(created_user).not_to be_onboarding_in_progress
      expect(created_user.onboarding_status_step_url).to be_nil
    end
  end
end
