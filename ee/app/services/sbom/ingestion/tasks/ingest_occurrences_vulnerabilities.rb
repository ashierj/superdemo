# frozen_string_literal: true

module Sbom
  module Ingestion
    module Tasks
      class IngestOccurrencesVulnerabilities < Base
        include Gitlab::Ingestion::BulkInsertableTask

        self.model = Sbom::OccurrencesVulnerability
        self.unique_by = %i[sbom_occurrence_id vulnerability_id]

        private

        def attributes
          occurrence_maps.flat_map do |occurrence_map|
            occurrence_map.vulnerability_ids.map do |vulnerability_id|
              {
                sbom_occurrence_id: occurrence_map.occurrence_id,
                vulnerability_id: vulnerability_id
              }
            end
          end
        end
      end
    end
  end
end
