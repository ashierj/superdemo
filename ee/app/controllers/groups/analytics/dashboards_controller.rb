# frozen_string_literal: true

module Groups
  module Analytics
    class DashboardsController < Groups::Analytics::ApplicationController
      include ProductAnalyticsTracking

      track_event :value_streams_dashboard,
        name: 'g_metrics_comparison_page',
        action: 'perform_analytics_usage_action',
        label: 'redis_hll_counters.analytics.g_metrics_comparison_page_monthly',
        destinations: %i[redis_hll snowplow]

      before_action { authorize_view_by_action!(:read_group_analytics_dashboards) }
      before_action :redirect_to_value_streams_dashboard, only: :index
      before_action do
        push_frontend_feature_flag(:dora_performers_score_panel, @group)
        push_frontend_feature_flag(:group_analytics_dashboards, @group)

        load_visualizations
      end

      layout 'group'

      VALUE_STREAM_VISUALIZATIONS_PATH = 'ee/lib/gitlab/analytics/value_stream_dashboard/visualizations/'

      # TODO: Once we remove the `group_analytics_dashboards` feature flag
      #       we should rename this route to `index` so we have a single entry point
      #       the `group_analytics_dashboard_dynamic_vsd` will toggle between the built-in
      #       VSD page and the VSD rendered via shared analytics dasboards
      def value_streams_dashboard
        respond_to do |format|
          format.html do
            @pointer_project = find_pointer_project

            @namespaces =
              if params[:query].present?
                paths_array = params[:query].split(",")
                sources = Route.inside_path(@group.full_path).where(path: paths_array).map(&:source) # rubocop:disable CodeReuse/ActiveRecord

                sources.map do |source|
                  {
                    name: source.name,
                    full_path: source.full_path,
                    is_project: project?(source)
                  }
                end
              else
                []
              end

            Gitlab::UsageDataCounters::ValueStreamsDashboardCounter.count(:views)

            render :index
          end
        end
      end

      private

      def load_visualizations
        return unless Feature.enabled?(:group_analytics_dashboards, @group)

        @available_visualizations = [load_yaml_dashboard_config(VALUE_STREAM_VISUALIZATIONS_PATH, "dora_chart.yaml")]
      end

      def load_yaml_dashboard_config(path, file)
        visualizations = YAML.safe_load(
          File.read(Rails.root.join(path, file))
        )

        visualizations[:slug] = file.gsub(".yaml", "")
        visualizations
      end

      def find_pointer_project
        project = @group.all_projects.find_by_id(@group.analytics_dashboards_pointer&.target_project_id)
        project&.as_json(only: %w[id name], methods: %w[full_path])
      end

      def project?(source)
        source.model_name.param_key == "project"
      end

      def tracking_namespace_source
        @group
      end

      def tracking_project_source
        nil
      end

      def redirect_to_value_streams_dashboard
        return if Feature.enabled?(:group_analytics_dashboards, @group)

        # Value streams dashboard has been moved into another action,
        # this is a temporary redirect to keep current bookmarks healthy.
        redirect_to(value_streams_dashboard_group_analytics_dashboards_path(@group, query: params[:query]))
      end
    end
  end
end
