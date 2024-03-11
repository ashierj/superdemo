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
    let(:step) { GitlabSubscriptions::Trials::CreateDuoProService::LEAD }
    let(:lead_params) do
      {
        company_name: '_company_name_',
        company_size: '1-99',
        first_name: '_first_name_',
        last_name: '_last_name_',
        phone_number: '123',
        country: '_country_',
        state: '_state_',
        website_url: '_website_url_'
      }.with_indifferent_access
    end

    let(:trial_params) do
      {
        namespace_id: group.id.to_s,
        trial_entity: '_trial_entity_'
      }.with_indifferent_access
    end

    let(:base_params) { lead_params.merge(trial_params).merge(step: step) }

    subject(:post_create) do
      post trials_duo_pro_path, params: base_params
      response
    end

    context 'when not authenticated' do
      it 'redirects to trial registration' do
        expect(post_create).to redirect_to_trial_registration
      end
    end

    context 'when authenticated' do
      shared_examples 'with tracking trial registration' do |event|
        it_behaves_like 'internal event tracking' do
          let(:event) { event }
          let(:namespace) { group }

          subject(:track_event) do
            post trials_duo_pro_path, params: base_params
          end
        end
      end

      before do
        login_as(user)
      end

      context 'when successful' do
        before do
          expect_create_success(group)
        end

        it 'redirects to group path' do
          expect(post_create).to redirect_to(group_path(group))
        end

        it_behaves_like 'with tracking trial registration', 'duo_pro_trial_registration_success'
      end

      context 'with create service failures' do
        let(:payload) { {} }

        before do
          expect_create_failure(failure_reason, payload)
        end

        context 'when namespace is not found or not allowed to create' do
          let(:failure_reason) { :not_found }

          it { is_expected.to have_gitlab_http_status(:not_found) }
        end

        context 'when lead creation fails' do
          let(:failure_reason) { :lead_failed }

          it 'renders lead form' do
            expect(post_create).to have_gitlab_http_status(:ok).and render_lead_form
          end
        end

        context 'when lead creation is successful, but we need to select a namespace next to apply trial' do
          let(:failure_reason) { :no_single_namespace }
          let(:payload) do
            {
              trial_selection_params: {
                step: GitlabSubscriptions::Trials::CreateDuoProService::TRIAL
              }
            }
          end

          it 'redirects to new with trial step' do
            post_create

            expect(response).to redirect_to(new_trials_duo_pro_path(payload[:trial_selection_params]))
          end
        end

        context 'with namespace creation failure' do
          let(:failure_reason) { :namespace_create_failed }
          let(:namespace) { build_stubbed(:namespace) }
          let(:payload) { { namespace: namespace.id } }

          it 'renders the select namespace form again with namespace creation errors only' do
            expect(post_create).to render_select_namespace

            expect(response.body).to include('data-namespace-create-errors="_error_"')
            expect(response.body).not_to include(_('We have found the following errors:'))
          end
        end

        context 'with trial failure' do
          let(:failure_reason) { :trial_failed }
          let(:namespace) { build_stubbed(:namespace) }
          let(:payload) { { namespace: namespace.id } }

          it 'renders the select namespace form again with trial creation errors only' do
            expect(post_create).to render_select_namespace

            expect(response.body).to include(_('We have found the following errors:'))
          end

          it_behaves_like 'with tracking trial registration', 'duo_pro_trial_registration_failure'
        end

        context 'with random failure' do
          let(:failure_reason) { :random_error }
          let(:namespace) { build_stubbed(:namespace) }
          let(:payload) { { namespace_id: namespace.id } }

          it { is_expected.to render_select_namespace }

          it_behaves_like 'with tracking trial registration', 'duo_pro_trial_registration_failure'
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

  def expect_create_success(namespace)
    service_params = {
      step: step,
      lead_params: lead_params,
      trial_params: trial_params,
      user: user
    }

    expect_next_instance_of(GitlabSubscriptions::Trials::CreateDuoProService, service_params) do |instance|
      expect(instance).to receive(:execute).and_return(ServiceResponse.success(payload: { namespace: namespace }))
    end
  end

  def expect_create_failure(reason, payload = {})
    expect_next_instance_of(GitlabSubscriptions::Trials::CreateDuoProService) do |instance|
      response = ServiceResponse.error(message: '_error_', reason: reason, payload: payload)
      expect(instance).to receive(:execute).and_return(response)
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
