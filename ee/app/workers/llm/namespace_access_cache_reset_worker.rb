# frozen_string_literal: true

module Llm
  class NamespaceAccessCacheResetWorker
    include Gitlab::EventStore::Subscriber

    data_consistency :delayed
    feature_category :ai_abstraction_layer
    urgency :low
    deduplicate :until_executed
    idempotent!

    def handle_event(event)
      group = Group.find_by_id(event.data[:group_id])
      return unless group

      Gitlab::Instrumentation::RedisClusterValidator.allow_cross_slot_commands do
        Rails.cache.delete_multi(cache_keys(group))
      end
    end

    def cache_keys(group)
      unique_group_users(group).map { |user| ["users", user.id, User::GROUP_WITH_AI_ENABLED_CACHE_KEY] }
    end

    def unique_group_users(group)
      User.from_union(
        [
          group.project_users_with_descendants.select(:id),
          group.users_with_descendants.select(:id)
        ],
        remove_duplicates: true
      ).select(:id)
    end
  end
end
