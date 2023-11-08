# frozen_string_literal: true

module Security
  module Ingestion
    class IngestSliceBaseService
      def self.execute(pipeline, finding_maps)
        new(pipeline, finding_maps).execute
      end

      def initialize(pipeline, finding_maps)
        @pipeline = pipeline
        @finding_maps = finding_maps
      end

      def execute
        ApplicationRecord.transaction do
          self.class::TASKS.each { |task| execute_task(task) }
        end

        @finding_maps.map(&:vulnerability_id)
      end

      private

      def execute_task(task)
        Tasks.const_get(task, false).execute(@pipeline, @finding_maps)
      end
    end
  end
end
