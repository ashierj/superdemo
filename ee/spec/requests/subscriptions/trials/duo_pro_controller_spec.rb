# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Subscriptions::Trials::DuoProController, feature_category: :purchase do
  let_it_be(:user, reload: true) { create(:user) }

  let(:duo_pro_trials_feature_flag) { true }
  let(:subscriptions_trials_saas_feature) { true }

  before do
    stub_feature_flags(duo_pro_trials: duo_pro_trials_feature_flag)

    stub_saas_features(
      subscriptions_trials: subscriptions_trials_saas_feature,
      marketing_google_tag_manager: false
    )
  end

  describe 'GET new' do
    let(:base_params) { {} }

    subject(:get_new) do
      get new_trials_duo_pro_path, params: base_params
      response
    end

    context 'when not authenticated' do
      it { is_expected.to redirect_to_trial_registration }
    end

    context 'when authenticated' do
      before do
        login_as(user)
      end

      it { is_expected.to render_lead_form }

      context 'when duo_pro_trials feature flag is disabled' do
        let(:duo_pro_trials_feature_flag) { false }

        it { is_expected.to have_gitlab_http_status(:not_found) }
      end

      context 'when subscriptions_trials saas feature is not available' do
        let(:subscriptions_trials_saas_feature) { false }

        it { is_expected.to have_gitlab_http_status(:not_found) }
      end

      context 'when on the trial step' do
        let(:base_params) { { step: 'trial' } }

        it { is_expected.to render_select_namespace }
      end
    end
  end

  describe 'POST create' do
    subject(:post_create) do
      post trials_duo_pro_path, params: {}
      response
    end

    context 'when not authenticated' do
      it 'redirects to trial registration' do
        expect(post_create).to redirect_to_trial_registration
      end
    end

    context 'when authenticated' do
      before do
        login_as(user)
      end

      context 'when successful' do
        it 'redirects to new path' do
          expect(post_create).to redirect_to(new_trials_duo_pro_path(
            step: GitlabSubscriptions::Trials::CreateService::TRIAL
          ))
        end
      end

      context 'when duo_pro_trials feature flag is disabled' do
        let(:duo_pro_trials_feature_flag) { false }

        it { is_expected.to have_gitlab_http_status(:not_found) }
      end

      context 'when subscriptions_trials saas feature is not available' do
        let(:subscriptions_trials_saas_feature) { false }

        it { is_expected.to have_gitlab_http_status(:not_found) }
      end
    end
  end

  RSpec::Matchers.define :render_lead_form do
    match do |response|
      expect(response).to have_gitlab_http_status(:ok)

      expect(response.body).to include(s_('DuoProTrial|Start your free Duo Pro trial'))

      expect(response.body).to include(
        s_('DuoProTrial|We just need some additional information to activate your trial.')
      )
    end
  end

  RSpec::Matchers.define :render_select_namespace do
    match do |response|
      expect(response).to have_gitlab_http_status(:ok)

      expect(response.body).to include(s_('DuoProTrial|Create a group to start your Duo Pro trial'))
    end
  end

  RSpec::Matchers.define :redirect_to_trial_registration do
    match do |response|
      expect(response).to redirect_to(new_trial_registration_path)
      expect(flash[:alert]).to include('You need to sign in or sign up before continuing')
    end
  end
end
