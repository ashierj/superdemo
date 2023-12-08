# frozen_string_literal: true

module Sbom
  module Ingestion
    class IngestReportService
      BATCH_SIZE = 10

      def self.execute(pipeline, sbom_report, vulnerabilities_info)
        new(pipeline, sbom_report, vulnerabilities_info).execute
      end

      def initialize(pipeline, sbom_report, vulnerabilities_info)
        @pipeline = pipeline
        @sbom_report = sbom_report
        @vulnerabilities_info = vulnerabilities_info
      end

      def execute
        occurrence_map_collection.each_slice(BATCH_SIZE).flat_map do |slice|
          ingest_slice(slice)
        end
      end

      private

      attr_reader :pipeline, :sbom_report, :vulnerabilities_info

      def occurrence_map_collection
        @occurrence_map_collection ||= OccurrenceMapCollection.new(sbom_report, vulnerabilities_info)
      end

      def ingest_slice(slice)
        IngestReportSliceService.execute(pipeline, slice)
      end
    end
  end
end
