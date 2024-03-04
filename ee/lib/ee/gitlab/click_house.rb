# frozen_string_literal: true

module EE
  module Gitlab
    module ClickHouse
      extend ActiveSupport::Concern

      class_methods do
        def enabled_for_analytics?(group = nil)
          configured? &&
            ::Gitlab::CurrentSettings.current_application_settings.use_clickhouse_for_analytics? &&
            ::Feature.enabled?(:clickhouse_data_collection, group)
        end
      end
    end
  end
end
