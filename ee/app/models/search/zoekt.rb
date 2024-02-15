# frozen_string_literal: true

module Search
  module Zoekt
    EXPIRED_SUBSCRIPTION_GRACE_PERIOD = 30.days

    class << self
      def fetch_node_id(container)
        root_namespace_id = fetch_root_namespace_id(container)
        return unless root_namespace_id

        ::Search::Zoekt::Index.for_root_namespace_id(root_namespace_id).first&.zoekt_node_id
      end

      def search?(container)
        root_namespace_id = fetch_root_namespace_id(container)
        return false unless root_namespace_id

        ::Search::Zoekt::Index.for_root_namespace_id_with_search_enabled(root_namespace_id).ready.exists?
      end

      def index?(container)
        root_namespace_id = fetch_root_namespace_id(container)
        return false unless root_namespace_id

        ::Search::Zoekt::Index.for_root_namespace_id(root_namespace_id).exists?
      end

      def enabled_for_user?(user)
        return false unless ::Feature.enabled?(:search_code_with_zoekt, user)
        return false unless ::License.feature_available?(:zoekt_code_search)
        return true unless user # anonymous users have access, the final check is the user's preference setting

        user.enabled_zoekt?
      end

      private

      def fetch_root_namespace_id(container)
        case container
        in Project | Namespace
          container.root_ancestor.id
        in Integer => root_namespace_id
          root_namespace_id
        else
          raise ArgumentError, "#{container.class} class is not supported"
        end
      end
    end
  end
end
