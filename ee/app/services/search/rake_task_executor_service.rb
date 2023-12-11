# frozen_string_literal: true

module Search
  class RakeTaskExecutorService
    include ActionView::Helpers::NumberHelper

    TASKS = %i[
      index_snippets
      pause_indexing
      resume_indexing
      estimate_cluster_size
      mark_reindex_failed
      list_pending_migrations
    ].freeze

    attr_reader :logger

    def initialize(logger:)
      @logger = logger
    end

    def execute(task)
      raise ArgumentError, "Unknown task: #{task}" unless TASKS.include?(task)
      raise NotImplementedError unless respond_to?(task, true)

      send(task) # rubocop:disable GitlabSecurity/PublicSend -- We control the list of tasks in the source code
    end

    private

    def index_snippets
      logger.info("Indexing snippets...")

      Snippet.es_import

      logger.info("Indexing snippets... #{'done'.color(:green)}")
    end

    def pause_indexing
      puts "Pausing indexing...".color(:green)

      if ::Gitlab::CurrentSettings.elasticsearch_pause_indexing?
        puts "Indexing is already paused.".color(:orange)
      else
        ::Gitlab::CurrentSettings.update!(elasticsearch_pause_indexing: true)
        puts "Indexing is now paused.".color(:green)
      end
    end

    def resume_indexing
      puts "Resuming indexing...".color(:green)

      if ::Gitlab::CurrentSettings.elasticsearch_pause_indexing?
        ::Gitlab::CurrentSettings.update!(elasticsearch_pause_indexing: false)
        puts "Indexing is now running.".color(:green)
      else
        puts "Indexing is already running.".color(:orange)
      end
    end

    def estimate_cluster_size
      total_size = Namespace::RootStorageStatistics.sum(:repository_size).to_i
      total_size_human = number_to_human_size(total_size, delimiter: ',', precision: 1, significant: false)

      estimated_cluster_size = total_size * 0.5
      estimated_cluster_size_human = number_to_human_size(estimated_cluster_size, delimiter: ',', precision: 1,
        significant: false)

      puts "This GitLab instance repository size is #{total_size_human}."
      puts "By our estimates for such repository size, " \
           "your cluster size should be at least #{estimated_cluster_size_human}.".color(:green)
      puts "Please note that it is possible to index only selected namespaces/projects by using " \
           "Elasticsearch indexing restrictions."
    end

    def mark_reindex_failed
      if ::Elastic::ReindexingTask.running?
        ::Elastic::ReindexingTask.current.failure!
        puts 'Marked the current reindexing job as failed.'.color(:green)
      else
        puts 'Did not find the current running reindexing job.'
      end
    end

    def list_pending_migrations
      pending_migrations = ::Elastic::DataMigrationService.pending_migrations

      if pending_migrations.any?
        display_pending_migrations(pending_migrations)
      else
        puts 'There are no pending migrations.'
      end
    end

    def display_pending_migrations(pending_migrations)
      puts "Pending Migrations".color(:yellow)
      pending_migrations.each do |migration|
        migration_info = migration.name
        migration_info << " [Obsolete]".color(:red) if migration.obsolete?
        puts migration_info
      end
    end
  end
end
