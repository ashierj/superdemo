# frozen_string_literal: true

require 'spec_helper'
require_relative '../product_analytics/dashboards_shared_examples'

RSpec.describe 'Analytics Dashboard - Product Analytics', :js, feature_category: :product_analytics_data_management do
  let_it_be(:current_user) { create(:user) }
  let_it_be(:user) { current_user }
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, :repository, group: group) }

  before do
    sign_in(user)
    allow(project.group.root_ancestor.namespace_settings).to receive(:experiment_settings_allowed?).and_return(true)
    project.group.root_ancestor.namespace_settings.update!(
      experiment_features_enabled: true,
      product_analytics_enabled: true
    )
    project.reload
  end

  subject(:visit_page) { visit project_analytics_dashboards_path(project) }

  it_behaves_like 'product analytics dashboards' do
    let(:project_settings) { { product_analytics_instrumentation_key: 456 } }
    let(:application_settings) do
      {
        product_analytics_configurator_connection_string: 'https://configurator.example.com',
        product_analytics_data_collector_host: 'https://collector.example.com',
        cube_api_base_url: 'https://cube.example.com',
        cube_api_key: '123'
      }
    end
  end
end

RSpec.describe 'Analytics Dashboard - Value Streams Dashboard', :js, feature_category: :value_stream_management do
  include ValueStreamsDashboardHelpers

  let_it_be(:current_user) { create(:user) }
  let_it_be(:user) { current_user }
  let_it_be(:group) { create(:group, name: "vsd test group") }
  let_it_be(:project) { create(:project, :repository, name: "vsd project", group: group) }

  let(:metric_table) { find_by_testid('panel-dora-chart') }

  it 'renders a 404 error for a user without permission' do
    sign_in(user)
    visit_project_analytics_dashboards_list(project)

    expect(page).to have_content _("Page Not Found")
  end

  context 'with a valid user' do
    before_all do
      project.add_developer(user)
    end

    context 'with combined_project_analytics_dashboards and project_level_analytics_dashboard license' do
      before do
        stub_licensed_features(combined_project_analytics_dashboards: true, project_level_analytics_dashboard: true,
          dora4_analytics: true, security_dashboard: true, cycle_analytics_for_projects: true)

        sign_in(user)
        visit_project_analytics_dashboards_list(project)
      end

      it 'renders the dashboard list correctly' do
        expect(page).to have_content _('Analytics dashboards')
        expect(page).to have_content _('Dashboards are created by editing the projects dashboard files')
      end

      it_behaves_like 'has value streams dashboard link'
      context 'for Value streams dashboard' do
        before do
          visit_project_value_streams_dashboard(project)
        end

        it_behaves_like 'VSD renders as an analytics dashboard'
        it_behaves_like 'renders link to the feedback survey'
        it_behaves_like 'renders usage overview metrics'
        it_behaves_like 'renders metrics comparison table'

        it 'renders the dora performers score with an error' do
          # Currently not supported at the project level
          dora_performers_score = find_by_testid('panel-dora-performers-score')
          expect(dora_performers_score).to be_visible

          panel_title = format(_("DORA performers score for %{name} group"), name: group.name)
          expect(dora_performers_score).to have_content panel_title
          expect(dora_performers_score).to have_content _("Something went wrong.")
        end

        it 'renders a title for the metrics comparison table' do
          expect(metric_table).to have_content format(_("Metrics comparison for %{name} group"), name: group.name)
        end

        it_behaves_like 'does not render contributor count'
      end
    end

    context 'with project_analytics_dashboard_dynamic_vsd feature flag disabled' do
      before do
        stub_feature_flags(project_analytics_dashboard_dynamic_vsd: false)

        visit_project_analytics_dashboards_list(project)
      end

      it 'does not render the value streams dashboard link' do
        expect(page).not_to have_content _('Value Streams Dashboard')
        expect(page).not_to have_selector dashboard_by_gitlab_testid
      end
    end
  end
end
