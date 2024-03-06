# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Subscriptions::Trials::DuoProController, feature_category: :purchase do
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be(:another_group) { create(:group) }

  let(:duo_pro_trials_feature_flag) { true }
  let(:subscriptions_trials_saas_feature) { true }

  before_all do
    group.add_owner(user)
  end

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

      context 'with tracking page render' do
        it_behaves_like 'internal event tracking' do
          let(:event) { 'render_duo_pro_lead_page' }

          subject(:track_event) do
            get new_trials_duo_pro_path, params: { namespace_id: another_group.id }
          end
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

      context 'when on the trial step' do
        let(:base_params) { { step: 'trial' } }

        it { is_expected.to render_select_namespace }

        context 'with tracking page render' do
          it_behaves_like 'internal event tracking' do
            let(:event) { 'render_duo_pro_trial_page' }
            let(:namespace) { group }

            subject(:track_event) do
              get new_trials_duo_pro_path, params: base_params.merge(namespace_id: group.id)
            end
          end
        end
      end
    end
  end

  describe 'POST create' do
    subject(:post_create) do
      post trials_duo_pro_path, params: { step: 'lead' }
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

      it 'redirects to new path' do
        expect(post_create).to redirect_to(new_trials_duo_pro_path(
          step: GitlabSubscriptions::Trials::CreateService::TRIAL
        ))
      end

      context 'with tracking lead creation' do
        it_behaves_like 'internal event tracking' do
          let(:event) { 'duo_pro_lead_creation_success' }
          let(:namespace) { group }

          subject(:track_event) do
            post trials_duo_pro_path, params: { step: 'lead', namespace_id: group.id }
          end
        end

        # TODO: Uncomment when actual duo pro trial is implemented
        # it_behaves_like 'internal event tracking' do
        #   let(:event) { 'duo_pro_lead_creation_failure' }

        #   subject(:track_event) do
        #     post trials_duo_pro_path, params: { step: 'lead', namespace_id: another_group.id }
        #   end
        # end
      end

      context 'when on the trial step' do
        let(:base_params) { { step: 'trial' } }

        context 'with tracking trial registration' do
          it_behaves_like 'internal event tracking' do
            let(:event) { 'duo_pro_trial_registration_success' }
            let(:namespace) { group }

            subject(:track_event) do
              post trials_duo_pro_path, params: { step: 'trial', namespace_id: group.id }
            end
          end

          # TODO: Uncomment when actual duo pro trial is implemented
          # it_behaves_like 'internal event tracking' do
          #   let(:event) { 'duo_pro_trial_registration_failure' }

          #   subject(:track_event) do
          #     post trials_duo_pro_path, params: { step: 'trial', namespace_id: another_group.id }
          #   end
          # end
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

      expect(response.body).to include(s_('DuoProTrial|Start your free GitLab Duo Pro trial'))

      expect(response.body).to include(
        s_('DuoProTrial|We just need some additional information to activate your trial.')
      )
    end
  end

  RSpec::Matchers.define :render_select_namespace do
    match do |response|
      expect(response).to have_gitlab_http_status(:ok)

      expect(response.body).to include(s_('DuoProTrial|Apply your GitLab Duo Pro trial to a new or existing group'))
    end
  end

  RSpec::Matchers.define :redirect_to_trial_registration do
    match do |response|
      expect(response).to redirect_to(new_trial_registration_path)
      expect(flash[:alert]).to include('You need to sign in or sign up before continuing')
    end
  end
end
