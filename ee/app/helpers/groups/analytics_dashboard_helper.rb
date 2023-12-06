# frozen_string_literal: true

module Groups
  module AnalyticsDashboardHelper
    def group_analytics_dashboard_available?(user, group)
      can?(user, :read_group_analytics_dashboards, group)
    end
  end
end
