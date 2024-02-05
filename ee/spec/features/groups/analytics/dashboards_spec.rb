# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Analytics Dashboard', :js, feature_category: :value_stream_management do
  let_it_be(:current_user) { create(:user) }
  let_it_be(:user) { current_user }
  let_it_be(:group) { create(:group, name: "vsd test group") }
  let_it_be(:project) { create(:project, :repository, name: "vsd project", group: group) }

  let(:metric_table) { find_by_testid('panel-dora-chart') }
  let(:metric_table_rows) { metric_table.all("tbody tr") }

  def visit_group_analytics_dashboards_list(group)
    visit group_analytics_dashboards_path(group)
  end

  def visit_group_value_streams_dashboard(group)
    visit group_analytics_dashboards_path(group)
    click_link "Value Streams Dashboard"

    wait_for_requests
  end

  legacy_vsd_testid = "[data-testid='legacy-vsd']"
  gridstack_grid_testid = "[data-testid='gridstack-grid']"
  dashboard_list_item_testid = "[data-testid='dashboard-list-item']"
  dashboard_by_gitlab_testid = "[data-testid='dashboard-by-gitlab']"
  contributor_count_testid = '[data-testid="dora-chart-metric-contributor-count"]'

  shared_examples 'renders usage overview metrics' do
    let(:usage_overview) { find_by_testid('panel-usage-overview') }

    it 'renders the metrics panel' do
      expect(usage_overview).to be_visible
      expect(usage_overview).to have_content _("Usage overview for vsd test group group")
    end

    it 'renders each of the available metrics' do
      usage_metrics = ["Groups", "Projects", "Issues", "Merge requests", "Pipelines"]

      within usage_overview do
        metric_titles = all('[data-testid="title-text"]').collect(&:text)

        expect(metric_titles.length).to eq usage_metrics.length
        expect(metric_titles).to match_array usage_metrics
      end
    end
  end

  shared_examples 'renders metrics comparison table' do
    available_metrics = [
      { name: "Deployment Frequency", values: ["0.0/d"] * 3, identifier: 'deployment-frequency' },
      { name: "Lead Time for Changes", values: ["0.0 d"] * 3, identifier: 'lead-time-for-changes' },
      { name: "Time to Restore Service", values: ["0.0 d"] * 3, identifier: 'time-to-restore-service' },
      { name: "Change Failure Rate", values: ["0.0%"] * 3, identifier: 'change-failure-rate' },
      { name: "Lead time", values: ["-"] * 3, identifier: 'lead-time' },
      { name: "Cycle time", values: ["-"] * 3, identifier: 'cycle-time' },
      { name: "Issues created", values: ["-"] * 3, identifier: 'issues' },
      { name: "Issues closed", values: ["-"] * 3, identifier: 'issues-completed' },
      { name: "Deploys", values: ["-"] * 3, identifier: 'deploys' },
      { name: "Merge request throughput", values: ["-"] * 3, identifier: 'merge-request-throughput' },
      { name: "Critical Vulnerabilities over time", values: ["-"] * 3, identifier: "vulnerability-critical" },
      { name: "High Vulnerabilities over time", values: ["-"] * 3, identifier: 'vulnerability-high' }
    ]

    def expect_metric(metric)
      row = find_by_testid("dora-chart-metric-#{metric[:identifier]}")

      expect(row).to be_visible

      expect(row).to have_content metric[:name]
      expect(row).to have_content metric[:values].join(" ")
    end

    it 'renders the metrics comparison visualization' do
      expect(metric_table).to be_visible
    end

    it "renders the available metrics" do
      wait_for_all_requests

      available_metrics.each do |metric|
        expect_metric(metric)
      end
    end
  end

  shared_examples 'renders dora performers score' do
    let(:dora_performers_score) { find_by_testid('panel-dora-performers-score') }
    let(:dora_performers_chart_title) { find_by_testid('dora-performers-score-chart-title') }

    it 'renders the dora performers score visualization' do
      expect(dora_performers_score).to be_visible

      expect(dora_performers_score).to have_content _("DORA performers score for vsd test group group")
      expect(dora_performers_chart_title).to have_content _("Total projects (0) with DORA metrics")
    end
  end

  shared_examples 'renders link to the feedback survey' do
    let(:feedback_survey) { find_by_testid('vsd-feedback-survery') }

    it 'renders feedback survey' do
      expect(feedback_survey).to be_visible
      expect(feedback_survey).to have_content _("To help us improve the Value Stream Management Dashboard, " \
                                                "please share feedback about your experience in this survey.")
    end
  end

  shared_examples 'VSD renders as an analytics dashboard' do
    it 'renders as an analytics dashboard' do
      expect(page).not_to have_selector legacy_vsd_testid

      expect(find_by_testid('gridstack-grid')).to be_visible
    end

    it 'does not render the group dashboard listing' do
      expect(page).not_to have_selector(dashboard_list_item_testid)

      expect(page).to have_content _('Value Streams Dashboard')
    end
  end

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

        it 'renders the value streams dashboard link' do
          dashboard_items = page.all(dashboard_list_item_testid)

          expect(dashboard_items.length).to eq(1)

          first_dashboard = page.all(dashboard_list_item_testid).first

          expect(first_dashboard).to have_content _('Value Streams Dashboard')
          expect(first_dashboard).to have_selector dashboard_by_gitlab_testid
        end
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
          expect(metric_table).to have_content _("Metrics comparison for vsd test group group")
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
        expect(comparison_title).to have_content _("Metrics comparison for vsd test group group")
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

      it 'does not render the contributor count metric' do
        expect(metric_table).not_to have_selector contributor_count_testid
      end
    end
  end
end
