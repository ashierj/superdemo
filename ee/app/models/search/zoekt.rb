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
