# frozen_string_literal: true

module Search
  module Elastic
    class TriggerIndexingWorker
      include ApplicationWorker
      prepend ::Elastic::IndexingControl
      prepend ::Geo::SkipSecondary

      INITIAL_TASK = :initiate
      TASKS = %i[namespaces projects snippets users].freeze

      data_consistency :delayed

      feature_category :global_search
      worker_resource_boundary :cpu
      idempotent!
      urgency :throttled

      def perform(task = INITIAL_TASK, options = {})
        return false unless Gitlab::CurrentSettings.elasticsearch_indexing?

        task = task&.to_sym
        raise ArgumentError, "Unknown task: #{task}" unless allowed_tasks.include?(task)

        options = options.with_indifferent_access

        case task
        when :initiate
          initiate(options)
        when :namespaces
          namespaces
        when :projects
          projects
        when :snippets
          snippets
        when :users
          users
        end
      end

      private

      def allowed_tasks
        [INITIAL_TASK] + TASKS
      end

      def initiate(options)
        skip_tasks = Array.wrap(options[:skip]).map(&:to_sym)
        tasks_to_schedule = TASKS - skip_tasks

        tasks_to_schedule.each do |task|
          self.class.perform_async(task, options)
        end
      end

      def namespaces
        Namespace.by_parent(nil).each_batch do |batch|
          batch = batch.preload(:route) # rubocop: disable CodeReuse/ActiveRecord -- Avoid N+1
          batch = batch.select(&:use_elasticsearch?)

          ElasticNamespaceIndexerWorker.bulk_perform_async_with_contexts(
            batch,
            arguments_proc: ->(namespace) { [namespace.id, :index] },
            context_proc: ->(namespace) { { namespace: namespace } }
          )
        end
      end

      def projects
        Project.each_batch do |batch|
          ::Preloaders::ProjectRootAncestorPreloader.new(batch, :namespace).execute
          batch = batch.select(&:maintaining_elasticsearch?)

          ::Elastic::ProcessInitialBookkeepingService.backfill_projects!(*batch)
        end
      end

      def snippets
        Snippet.es_import
      end

      def users
        User.each_batch do |users|
          ::Elastic::ProcessInitialBookkeepingService.track!(*users)
        end
      end
    end
  end
end
