# frozen_string_literal: true

module Search
  module Zoekt
    class SchedulingService
      include Gitlab::Loggable

      TASKS = %i[
        node_assignment
      ].freeze

      BUFFER_FACTOR = 3
      WATERMARK_LIMIT = 0.8

      attr_reader :task

      def initialize(task)
        @task = task
      end

      def execute
        raise ArgumentError, "Unknown task: #{task}" unless TASKS.include?(task)
        raise NotImplementedError unless respond_to?(task, true)

        send(task) # rubocop:disable GitlabSecurity/PublicSend -- We control the list of tasks in the source code
      end

      def self.execute(task)
        new(task).execute
      end

      private

      def logger
        @logger ||= ::Zoekt::Logger.build
      end

      def node_assignment
        EnabledNamespace.with_missing_indices.preload_storage_statistics.find_each do |zoekt_enabled_namespace|
          storage_statistics = zoekt_enabled_namespace.namespace.root_storage_statistics
          unless storage_statistics
            logger.error(build_structured_payload(task: :node_assignment,
              message: "RootStorageStatistics isn't available", zoekt_enabled_namespace_id: zoekt_enabled_namespace.id))
            next
          end

          Node.descending_order_by_free_bytes.each do |node|
            space_required = BUFFER_FACTOR * storage_statistics.repository_size
            if (node.used_bytes + space_required) <= node.total_bytes * WATERMARK_LIMIT
              # TODO: Once we have the task which moves pending to ready then remove the state attribute from here
              # https://gitlab.com/gitlab-org/gitlab/-/issues/439042
              zoekt_index = Search::Zoekt::Index.new(namespace_id: zoekt_enabled_namespace.root_namespace_id,
                zoekt_node_id: node.id, zoekt_enabled_namespace: zoekt_enabled_namespace, state: :ready)

              unless zoekt_index.save
                logger.error(build_structured_payload(task: :node_assignment,
                  message: 'Could not save Search::Zoekt::Index', zoekt_index: zoekt_index.attributes.compact))
              end

              break
            else
              logger.error(build_structured_payload(task: :node_assignment, message: 'Space is not available in Node',
                zoekt_enabled_namespace_id: zoekt_enabled_namespace.id, node_id: node.id))
              next
            end
          end
        end
      end
    end
  end
end
