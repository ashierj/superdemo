# frozen_string_literal: true

module Search
  module Zoekt
    class << self
      def fetch_node_id(container)
        case container
        in Project | Namespace
          ::Zoekt::IndexedNamespace.find_by_namespace_id(container.root_ancestor.id)&.zoekt_node_id
        in Integer => id
          ::Zoekt::IndexedNamespace.find_by_namespace_id(id)&.zoekt_node_id
        else
          raise ArgumentError, "#{container.class} class is not supported"
        end
      end

      def search?(container)
        ::Search::Zoekt::IndexedNamespacesFinder.execute(container: container, params: { search: true }).exists?
      end

      def index?(container)
        ::Search::Zoekt::IndexedNamespacesFinder.execute(container: container).exists?
      end
    end
  end
end
