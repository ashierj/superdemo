# frozen_string_literal: true

module SystemCheck
  module Geo
    class DatabaseReplicationWorkingCheck < SystemCheck::BaseCheck
      set_name 'Database replication working?'
      set_skip_reason 'not a secondary node'

      def skip?
        !Gitlab::Geo.secondary?
      end

      def check?
        geo_health_check.replication_enabled? && geo_health_check.replication_working?
      end

      def show_error
        try_fixing_it(
          'Follow Geo setup instructions to configure primary and secondary nodes for replication'
        )

        help_page = construct_help_page_url('administration/geo/setup/database')
        for_more_information(help_page)
      end

      private

      def geo_health_check
        @geo_health_check ||= Gitlab::Geo::HealthCheck.new
      end
    end
  end
end
