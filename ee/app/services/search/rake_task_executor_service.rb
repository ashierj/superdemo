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
      enable_search_with_elasticsearch
      index_projects_status
      index_users
      index_projects
      index_epics
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

    def enable_search_with_elasticsearch
      if Gitlab::CurrentSettings.elasticsearch_search?
        puts "Setting `elasticsearch_search` was already enabled."
      else
        ApplicationSettings::UpdateService.new(
          Gitlab::CurrentSettings.current_application_settings,
          nil,
          { elasticsearch_search: true }
        ).execute

        puts "Setting `elasticsearch_search` has been enabled."
      end
    end

    def index_projects_status
      projects = elastic_enabled_projects.size
      indexed = IndexStatus.for_project(elastic_enabled_projects).size
      percent = (indexed / projects.to_f) * 100.0

      puts format("Indexing is %.2f%% complete (%d/%d projects)", percent, indexed, projects)
    end

    def index_users
      logger = Logger.new($stdout)
      logger.info("Indexing users...")

      User.each_batch do |users|
        ::Elastic::ProcessInitialBookkeepingService.track!(*users)
      end

      logger.info("Indexing users... #{'done'.color(:green)}")
    end

    def index_projects
      print "Enqueuing projects…"

      count = project_id_batches do |ids|
        ::Elastic::ProcessInitialBookkeepingService.backfill_projects!(*Project.find(ids))
        print "."
      end

      marker = count > 0 ? "✔" : "∅"
      puts " #{marker} (#{count})"
    end

    def index_epics
      logger = Logger.new($stdout)
      logger.info("Indexing epics...")

      groups = if ::Gitlab::CurrentSettings.elasticsearch_limit_indexing?
                 ::Gitlab::CurrentSettings.elasticsearch_limited_namespaces.where(type: "Group") # rubocop:disable CodeReuse/ActiveRecord -- This has been moved from ee/lib/tasks/gitlab/elastic.rake
               else
                 Group.all
               end

      groups.each_batch do |batch|
        ::Elastic::ProcessInitialBookkeepingService.maintain_indexed_group_associations!(*batch)
      end

      logger.info("Indexing epics... #{'done'.color(:green)}")
    end

    def display_pending_migrations(pending_migrations)
      puts "Pending Migrations".color(:yellow)
      pending_migrations.each do |migration|
        migration_info = migration.name
        migration_info << " [Obsolete]".color(:red) if migration.obsolete?
        puts migration_info
      end
    end

    def elastic_enabled_projects
      return Project.all unless ::Gitlab::CurrentSettings.elasticsearch_limit_indexing?

      ::Gitlab::CurrentSettings.elasticsearch_limited_projects
    end

    def project_id_batches
      relation = Project.all

      if ::Gitlab::CurrentSettings.elasticsearch_limit_indexing?
        relation.merge!(::Gitlab::CurrentSettings.elasticsearch_limited_projects)
      end

      count = 0
      relation.in_batches(start: ENV['ID_FROM'], finish: ENV['ID_TO']) do |relation| # rubocop:disable Cop/InBatches -- We need start/finish IDs here
        ids = relation.reorder(:id).pluck(:id) # rubocop:disable CodeReuse/ActiveRecord,Database/AvoidUsingPluckWithoutLimit -- this was ported from elastic.rake
        yield ids

        count += ids.size
      end

      count
    end
  end
end
