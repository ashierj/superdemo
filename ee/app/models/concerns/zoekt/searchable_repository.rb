# frozen_string_literal: true

module Zoekt
  module SearchableRepository
    extend ActiveSupport::Concern

    included do
      def use_zoekt?
        project&.use_zoekt?
      end

      def update_zoekt_index!
        shard_id = ::Zoekt::IndexedNamespace.find_by_namespace_id(project.root_ancestor.id).zoekt_shard_id
        ::Gitlab::Search::Zoekt::Client.index(project, shard_id)
      end

      def async_update_zoekt_index
        ::Zoekt::IndexerWorker.perform_async(project.id)
      end
    end
  end
end
