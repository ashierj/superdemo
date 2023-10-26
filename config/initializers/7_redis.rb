# frozen_string_literal: true

require 'gitlab/redis'

Redis.raise_deprecations = true unless Rails.env.production?

# rubocop:disable Gitlab/NoCodeCoverageComment
# :nocov: This snippet is for local development only, reloading in specs would raise NameError
if Rails.env.development?
  # reset all pools in the event of a reload
  # This makes sure that there are no stale references to classes in the `Gitlab::Redis` namespace
  # that also got reloaded.
  Gitlab::Application.config.to_prepare do
    Gitlab::Redis::ALL_CLASSES.each do |redis_instance|
      redis_instance.instance_variable_set(:@pool, nil)
    end

    Rails.cache = ActiveSupport::Cache::RedisCacheStore.new(**Gitlab::Redis::Cache.active_support_config)
  end
end
# :nocov:
# rubocop:enable Gitlab/NoCodeCoverageComment

Redis::Client.prepend(Gitlab::Instrumentation::RedisInterceptor)
Redis::Cluster::NodeLoader.prepend(Gitlab::Patch::NodeLoader)
Redis::Cluster::SlotLoader.prepend(Gitlab::Patch::SlotLoader)
Redis::Cluster::CommandLoader.prepend(Gitlab::Patch::CommandLoader)
Redis::Cluster.prepend(Gitlab::Patch::RedisCluster)

if Gitlab::Redis::Workhorse.params[:cluster].present?
  raise "Do not configure workhorse with a Redis Cluster as pub/sub commands are not cluster-compatible."
end

# Make sure we initialize a Redis connection pool before multi-threaded
# execution starts by
# 1. Sidekiq
# 2. Rails.cache
# 3. HTTP clients
Gitlab::Redis::ALL_CLASSES.each do |redis_instance|
  redis_instance.with { nil }
end
