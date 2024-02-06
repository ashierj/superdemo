# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Analytics Dashboard', :js, feature_category: :value_stream_management do
  include ValueStreamsDashboardHelpers

  let_it_be(:current_user) { create(:user) }
  let_it_be(:user) { current_user }
  let_it_be(:group) { create(:group, name: "vsd test group") }
  let_it_be(:project) { create(:project, :repository, name: "vsd project", group: group) }

  let(:metric_table) { find_by_testid('panel-dora-chart') }

  gridstack_grid_testid = "[data-testid='gridstack-grid']"

  it 'renders a 403 error for a user without permission' do
    sign_in(user)
    visit group_analytics_dashboards_path(group)

    expect(page).to have_content _("You don't have the permission to access this page")
  end

  context 'with a valid user' do
    before_all do
      group.add_developer(user)
    end

    context 'with group_level_analytics_dashboard license' do
      before do
        stub_licensed_features(group_level_analytics_dashboard: true, dora4_analytics: true, security_dashboard: true,
          cycle_analytics_for_groups: true)

        sign_in(user)
      end

      context 'for dashboard listing' do
        before do
          visit_group_analytics_dashboards_list(group)
        end

        it 'renders the dashboard list correctly' do
          expect(page).to have_content _('Analytics dashboards')
          expect(page).to have_content _('Dashboards are created by editing the groups dashboard files')
        end

        it_behaves_like 'has value streams dashboard link'
      end

      context 'for Value streams dashboard' do
        before do
          visit_group_value_streams_dashboard(group)
        end

        it_behaves_like 'VSD renders as an analytics dashboard'
        it_behaves_like 'renders link to the feedback survey'
        it_behaves_like 'renders usage overview metrics'
        it_behaves_like 'renders dora performers score'

        it_behaves_like 'renders metrics comparison table'

        it 'renders a title for the metrics comparison table' do
          expect(metric_table).to have_content format(_("Metrics comparison for %{name} group"), name: group.name)
        end
      end
    end

    context 'with legacy value streams dashboard' do
      before do
        stub_licensed_features(group_level_analytics_dashboard: true, dora4_analytics: true, security_dashboard: true,
          cycle_analytics_for_groups: true)
        stub_feature_flags(group_analytics_dashboard_dynamic_vsd: false)

        sign_in(user)

        visit_group_value_streams_dashboard(group)
      end

      it 'renders the legacy VSD page' do
        expect(page).not_to have_selector gridstack_grid_testid
        expect(find_by_testid('legacy-vsd')).to be_visible

        expect(page).to have_content _("Value Streams Dashboard")
        expect(page).to have_content _("The Value Streams Dashboard allows all stakeholders from executives to " \
                                       "individual contributors to identify trends, patterns, and opportunities " \
                                       "for software development improvements. Learn more.")
      end

      it_behaves_like 'renders link to the feedback survey'
      it_behaves_like 'renders dora performers score'

      it_behaves_like 'renders metrics comparison table'

      it 'renders a title for the metrics comparison table' do
        comparison_title = find_by_testid('comparison-chart-title')
        expect(comparison_title).to have_content format(_('Metrics comparison for %{name} group'), name: group.name)
      end
    end

    context 'with clickhouse_data_collection disabled', :saas do
      before do
        stub_licensed_features(group_level_analytics_dashboard: true, dora4_analytics: true, security_dashboard: true,
          cycle_analytics_for_groups: true)
        stub_feature_flags(clickhouse_data_collection: false)

        sign_in(user)

        visit_group_value_streams_dashboard(group)
      end

      it_behaves_like 'does not render contributor count'
    end
  end
end
