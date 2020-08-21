# frozen_string_literal: true

module RedisTrackingHelper
  extend ActiveSupport::Concern

  # Example:
  #
  # # In controller include helper
  # # Track event for index action
  #
  # include RedisTrackingHelper
  #
  # track_redis_hll_event :index, :show, name: 'i_analytics_dev_ops_score', feature: :my_feature
  #
  class_methods do
    def track_redis_hll_events(*controller_actions, name:, feature:)
      after_action only: controller_actions, if: -> { request.format.html? && request.headers['DNT'] != '1' } do
        track_unique_redis_hll_event(name, feature)
      end
    end
  end

  def track_unique_redis_hll_event(event_name, feature)
    return unless metric_feature_enabled?(feature)
    return unless Gitlab::CurrentSettings.usage_ping_enabled?
    return unless visitor_id

    Gitlab::UsageDataCounters::HLLRedisCounter.track_event(visitor_id, event_name)
  end

  private

  def metric_feature_enabled?(feature)
    Feature.enabled?(feature)
  end

  def visitor_id
    return cookies[:visitor_id] if cookies[:visitor_id].present?
    return unless current_user

    uuid = SecureRandom.uuid
    cookies[:visitor_id] = { value: uuid, expires: 24.months }
    uuid
  end
end
