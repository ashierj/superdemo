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
      unique_group_user_ids(group).map { |user_id| ["users", user_id, User::GROUP_WITH_AI_ENABLED_CACHE_KEY] }
    end

    def unique_group_user_ids(group)
      Member.from_union(
        [
          group.descendant_project_members_with_inactive.select(:user_id),
          group.members_with_descendants.select(:user_id)
        ],
        remove_duplicates: true
      ).pluck_user_ids
    end
  end
end
