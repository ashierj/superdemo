# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Group > Members > Unlimited members alert', :js, :saas,
  feature_category: :subgroups do
  let(:alert_selector) { '[data-testid="unlimited-members-during-trial-alert"]' }
  let_it_be(:group) { create(:group, :private, name: 'unlimited-members-during-trial-alert-group') }
  let_it_be(:subgroup) { create(:group, :private, parent: group, name: 'subgroup') }
  let_it_be(:user) { create(:user) }

  context 'when group not in trial' do
    it 'does not display alert' do
      group.add_owner(user)
      sign_in(user)

      visit group_group_members_path(group)

      wait_for_all_requests

      expect(page).not_to have_selector(alert_selector)
    end
  end

  context 'when group is in trial' do
    before do
      create(:gitlab_subscription, :active_trial, namespace: group)

      stub_ee_application_setting(dashboard_limit_enabled: true)
    end

    context 'when user is not owner' do
      it 'does not display alert' do
        group.add_maintainer(user)
        sign_in(user)

        visit group_group_members_path(group)

        wait_for_all_requests

        expect(page).not_to have_selector(alert_selector)
      end
    end

    context 'when user is owner' do
      before do
        group.add_owner(user)

        sign_in(user)
      end

      it_behaves_like 'unlimited members during trial alert' do
        let_it_be(:page_path) { group_group_members_path(group) }
      end
    end

    context 'when group is subgroup' do
      before do
        group.add_owner(user)
        subgroup.add_owner(user)

        sign_in(user)
      end

      it_behaves_like 'unlimited members during trial alert' do
        let_it_be(:page_path) { group_group_members_path(subgroup) }
      end
    end
  end
end
