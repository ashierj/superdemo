# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Analytics Dashboard Visualizations', :js, feature_category: :value_stream_management do
  include ValueStreamsDashboardHelpers

  let_it_be(:current_user) { create(:user) }
  let_it_be(:user) { current_user }
  let_it_be(:group) { create(:group, name: "vsd test group") }
  let_it_be(:project) { create(:project, :repository, name: "vsd project", group: group) }

  before_all do
    group.add_developer(user)
  end

  context 'for dora_chart visualization' do
    context 'with all features enabled', :saas do
      before do
        stub_licensed_features(group_level_analytics_dashboard: true, dora4_analytics: true, security_dashboard: true,
          cycle_analytics_for_groups: true)

        allow(Gitlab::ClickHouse).to receive(:enabled_for_analytics?).and_return(true)

        sign_in(user)

        visit_group_value_streams_dashboard(group)
      end

      it_behaves_like 'renders metrics comparison table' do
        let(:group_name) { group.name }
      end

      it_behaves_like 'renders contributor count'
    end

    context 'when ClickHouse is disabled for analytics', :saas do
      before do
        stub_licensed_features(group_level_analytics_dashboard: true, dora4_analytics: true, security_dashboard: true,
          cycle_analytics_for_groups: true)

        allow(Gitlab::ClickHouse).to receive(:enabled_for_analytics?).and_return(false)

        sign_in(user)

        visit_group_value_streams_dashboard(group)
      end

      it_behaves_like 'does not render contributor count'
    end
  end

  context 'for usage_overview visualization' do
    before do
      stub_licensed_features(group_level_analytics_dashboard: true)

      sign_in(user)

      visit_group_value_streams_dashboard(group)
    end

    it_behaves_like 'renders usage overview metrics'
  end

  context 'for dora_performers_score visualization' do
    before do
      stub_licensed_features(group_level_analytics_dashboard: true)

      sign_in(user)

      visit_group_value_streams_dashboard(group)
    end

    it_behaves_like 'renders dora performers score'
  end

  context 'with legacy value streams dashboard' do
    before do
      stub_feature_flags(group_analytics_dashboard_dynamic_vsd: false)
      stub_licensed_features(group_level_analytics_dashboard: true, dora4_analytics: true, security_dashboard: true,
        cycle_analytics_for_groups: true)

      allow(Gitlab::ClickHouse).to receive(:enabled_for_analytics?).and_return(true)

      sign_in(user)

      visit_group_value_streams_dashboard(group)
    end

    it_behaves_like 'renders metrics comparison table' do
      let(:group_name) { group.name }
    end

    it_behaves_like 'renders contributor count'
    it_behaves_like 'does not render usage overview metrics'
    it_behaves_like 'renders dora performers score'
  end
end
