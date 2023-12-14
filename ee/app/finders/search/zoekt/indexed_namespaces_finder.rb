# frozen_string_literal: true

# For finding namespaces that are indexed with zoekt
#
# Arguments:
#   container - Project or Namespace objects supported
#   params:
#     search: boolean
#
module Search
  module Zoekt
    class IndexedNamespacesFinder
      def initialize(container: nil, params: {})
        @container = container
        @params = params.with_indifferent_access
      end

      def execute
        items = ::Zoekt::IndexedNamespace.all

        items = by_container(items) if container
        items = by_search(items) if search?

        items
      end

      def self.execute(...)
        new(...).execute
      end

      private

      attr_reader :params, :container

      def search?
        params[:search].present?
      end

      def by_container(items)
        case container
        in Project | Namespace
          items.for_namespace(container.root_ancestor)
        else
          raise ArgumentError, "#{container.class} class is not supported"
        end
      end

      def by_search(items)
        items.search_enabled
      end
    end
  end
end
