# frozen_string_literal: true

module Ci
  module PipelineCreation
    class DropNotRunnableBuildsService
      include ::Gitlab::Utils::StrongMemoize

      def initialize(pipeline)
        @pipeline = pipeline

        runners_availability = ::Gitlab::Ci::RunnersAvailabilityBuilder.instance_for(pipeline.project)
        @runner_minutes = runners_availability.minutes_checker
      end

      ##
      # We want to run this service exactly once,
      # before the first pipeline processing call
      #
      def execute
        return unless pipeline.created?

        drop_non_matching_jobs
      end

      private

      attr_reader :pipeline
      attr_reader :runner_minutes

      delegate :project, to: :pipeline

      def drop_non_matching_jobs
        drop_by_pipeline_minutes
      end

      def drop_by_pipeline_minutes
        build_ids = build_matchers
          .filter_map { |matcher| matcher.build_ids unless runner_minutes.available?(matcher) }
          .flatten

        drop_all_builds(build_ids, :ci_quota_exceeded)
      end

      def build_matchers
        pipeline.build_matchers
      end
      strong_memoize_attr :build_matchers

      ##
      # We skip pipeline processing until we drop all required builds. Otherwise
      # as we drop the first build, the remaining builds to be dropped could
      # transition to other states by `PipelineProcessWorker` running async.
      #
      def drop_all_builds(build_ids, failure_reason)
        return if build_ids.empty?

        pipeline.builds.id_in(build_ids).each do |build|
          build.drop!(failure_reason, skip_pipeline_processing: true)
        end
      end
    end
  end
end
