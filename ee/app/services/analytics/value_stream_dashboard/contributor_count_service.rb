# frozen_string_literal: true

module Analytics
  module ValueStreamDashboard
    class ContributorCountService
      include Gitlab::Allowable

      QUERY = <<~SQL
      SELECT count(distinct "contributions"."author_id") AS contributor_count
      FROM (
        SELECT
          argMax(author_id, contributions.updated_at) AS author_id
        FROM contributions
          WHERE startsWith("contributions"."path", {group_path:String})
          AND "contributions"."created_at" >= {from:Date}
          AND "contributions"."created_at" <= {to:Date}
        GROUP BY id
      ) contributions
      SQL

      def initialize(group:, current_user:, from:, to:)
        @group = group
        @current_user = current_user
        @from = from
        @to = to
      end

      def execute
        return feature_unavailable_error unless Feature.enabled?(:clickhouse_data_collection, group)
        return not_authorized_error unless can?(current_user, :read_group_analytics_dashboards, group)

        ServiceResponse.success(payload: { count: contributor_count })
      end

      private

      attr_reader :group, :current_user, :from, :to

      def feature_unavailable_error
        ServiceResponse.error(
          message: s_('VsdContributorCount|the ClickHouse data store is not available for this group')
        )
      end

      def not_authorized_error
        ServiceResponse.error(message: s_('404|Not found'))
      end

      def contributor_count
        query = ClickHouse::Client::Query.new(raw_query: QUERY, placeholders: placeholders)
        ClickHouse::Client.select(query, :main).first['contributor_count']
      end

      def group_path
        @group_path ||= "#{group.traversal_ids.join('/')}/"
      end

      def format_date(date)
        date.strftime('%Y-%m-%d')
      end

      def placeholders
        {
          group_path: group_path,
          from: format_date(from),
          to: format_date(to)
        }
      end
    end
  end
end
