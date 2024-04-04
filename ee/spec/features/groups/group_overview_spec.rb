# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Group information', :js, :aggregate_failures, feature_category: :groups_and_projects do
  include BillableMembersHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }

  let(:role) { :owner }

  subject(:visit_page) { visit group_path(group) }

  before do
    group.add_member(user, role)
    sign_in(user)
  end

  context 'when the default value of "Group information content" preference is used' do
    it 'displays the Details view' do
      visit_page

      page.within(find('.content')) do
        expect(page).to have_content _('Subgroups and projects')
        expect(page).to have_content _('Shared projects')
        expect(page).to have_content _('Inactive')
      end
    end
  end

  context 'when Security Dashboard view is set as default' do
    before do
      stub_licensed_features(security_dashboard: true)
      enable_namespace_license_check!
    end

    let(:user) { create(:user, group_view: :security_dashboard) }

    context 'and Security Dashboard feature is not available for a group', :saas do
      let(:group) { create(:group_with_plan, plan: :bronze_plan) }

      it 'displays the "Security Dashboard unavailable" empty state' do
        visit_page

        page.within(find('.content')) do
          expect(page).to have_content s_("SecurityReports|Either you don't have permission to view this dashboard or "\
                                       'the dashboard has not been setup. Please check your permission settings '\
                                       'with your administrator or check your dashboard configurations to proceed.')
        end
      end
    end
  end

  describe 'qrtly reconciliation alert' do
    context 'on self-managed' do
      before do
        visit_page
      end

      it_behaves_like 'a hidden qrtly reconciliation alert'
    end

    context 'on dotcom', :saas do
      before do
        stub_ee_application_setting(should_check_namespace_plan: true)
      end

      context 'when qrtly reconciliation is available' do
        let!(:upcoming_reconciliation) { create(:upcoming_reconciliation, :saas, namespace: group) }

        before do
          visit_page
        end

        it_behaves_like 'a visible dismissible qrtly reconciliation alert'
      end

      context 'when qrtly reconciliation is not available' do
        before do
          visit_page
        end

        it_behaves_like 'a hidden qrtly reconciliation alert'
      end
    end
  end

  context 'when over free user limit', :saas do
    let_it_be(:group) { create(:group_with_plan, :private, plan: :free_plan) }

    it_behaves_like 'over the free user limit alert'
  end

  context 'when there is a seat overage', :saas, :use_clean_rails_memory_store_caching do
    let_it_be(:subscription) { create(:gitlab_subscription, :premium, namespace: group, seats: 1) }

    before_all do
      group.add_developer(create(:user))
    end

    before do
      stub_feature_flags(block_seat_overages: true)

      stub_billable_members_reactive_cache(group)
    end

    it 'displays an overage banner' do
      visit_page

      expect(page).to have_text "Your top-level group #{group.name} is now read-only."
    end
  end
end
