# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Groups::DiscoversController, :saas, feature_category: :activation do
  let_it_be(:owner) { create(:user) }
  let_it_be(:maintainer) { create(:user) }
  let_it_be(:developer) { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be(:gitlab_subscription) do
    create(:gitlab_subscription, :active_trial, :ultimate_trial, namespace: group, trial_ends_on: Date.tomorrow)
  end

  before_all do
    group.add_developer(developer)
    group.add_maintainer(maintainer)
    group.add_owner(owner)
  end

  describe 'GET show' do
    before do
      allow(Gitlab::CurrentSettings).to receive(:should_check_namespace_plan?).and_return(true)
    end

    subject { response }

    shared_examples 'unauthorized' do
      context 'and user is control' do
        before do
          stub_experiments(trial_discover_page: :control)
        end

        it 'renders index with 404 status code' do
          get group_discover_path(group)

          is_expected.to have_gitlab_http_status(:not_found)
          is_expected.not_to render_template(:show)
        end
      end

      context 'and user is candidate' do
        before do
          stub_experiments(trial_discover_page: :candidate)
        end

        it 'renders index with 404 status code' do
          get group_discover_path(group)

          is_expected.to have_gitlab_http_status(:not_found)
          is_expected.not_to render_template(:show)
        end
      end
    end

    context 'when trial_discover_page experiment is running' do
      before do
        allow_next_instance_of(GitlabSubscriptions::FetchSubscriptionPlansService) do |instance|
          allow(instance).to receive(:execute).and_return([])
        end
      end

      context 'when user is owner' do
        before do
          sign_in(owner)
        end

        context 'and user is control' do
          before do
            stub_experiments(trial_discover_page: :control)
          end

          it 'renders index with 404 status code' do
            get group_discover_path(group)

            is_expected.to have_gitlab_http_status(:not_found)
            is_expected.not_to render_template(:show)
          end
        end

        context 'and user is candidate' do
          before do
            stub_experiments(trial_discover_page: :candidate)
          end

          it 'renders index with 200 status code' do
            get group_discover_path(group)

            is_expected.to have_gitlab_http_status(:ok)
            is_expected.to render_template(:show)
          end
        end
      end

      context 'when user is maintainer' do
        before do
          sign_in(maintainer)
        end

        it_behaves_like 'unauthorized'
      end

      context 'when user is developer' do
        before do
          sign_in(developer)
        end

        it_behaves_like 'unauthorized'
      end
    end

    it 'renders 404 when the namespace check is disabled' do
      allow(Gitlab::CurrentSettings).to receive(:should_check_namespace_plan?).and_return(false)
      stub_experiments(trial_discover_page: :candidate)
      sign_in(owner)

      get group_discover_path(group)

      is_expected.to have_gitlab_http_status(:not_found)
    end

    context 'when group is not on trial' do
      let_it_be(:group) { create(:group) }
      let_it_be(:expired_subscription) do
        create(:gitlab_subscription, :expired_trial, :free, namespace: group, trial_ends_on: 1.day.ago)
      end

      it 'renders page when group has an expired trial' do
        stub_experiments(trial_discover_page: :candidate)
        group.add_owner(owner)
        sign_in(owner)

        get group_discover_path(group)

        is_expected.to have_gitlab_http_status(:ok)
      end
    end
  end
end
