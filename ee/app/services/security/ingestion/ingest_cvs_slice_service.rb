# frozen_string_literal: true

module Security
  module Ingestion
    class IngestCvsSliceService < IngestSliceBaseService
      TASKS = %i[
        IngestIdentifiers
        IngestFindings
        IngestVulnerabilities
        AttachFindingsToVulnerabilities
        IngestFindingPipelines
        IngestFindingIdentifiers
        IngestFindingLinks
        IngestFindingSignatures
        IngestFindingEvidence
        IngestVulnerabilityFlags
        IngestVulnerabilityStatistics
        HooksExecution
      ].freeze

      def self.execute(finding_maps)
        super(nil, finding_maps)
      end
    end
  end
end
