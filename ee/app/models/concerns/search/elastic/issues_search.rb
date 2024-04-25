# frozen_string_literal: true

module Search
  module Elastic
    module IssuesSearch
      extend ActiveSupport::Concern

      include ::Elastic::ApplicationVersionedSearch

      included do
        extend ::Gitlab::Utils::Override

        override :maintain_elasticsearch_create
        def maintain_elasticsearch_create
          super unless skip_indexing_for_group_work_items?
        end

        override :maintain_elasticsearch_update
        def maintain_elasticsearch_update(updated_attributes: previous_changes.keys)
          super unless skip_indexing_for_group_work_items?
        end

        override :maintain_elasticsearch_destroy
        def maintain_elasticsearch_destroy
          super unless skip_indexing_for_group_work_items?
        end
      end

      private

      def skip_indexing_for_group_work_items?
        is_a?(WorkItem) && project.nil?
      end
    end
  end
end
