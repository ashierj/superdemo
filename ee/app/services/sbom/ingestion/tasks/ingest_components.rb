# frozen_string_literal: true

module Sbom
  module Ingestion
    module Tasks
      class IngestComponents < Base
        COMPONENT_ATTRIBUTES = %i[name purl_type component_type].freeze

        self.model = Sbom::Component
        self.unique_by = COMPONENT_ATTRIBUTES
        self.uses = %i[id name purl_type component_type].freeze

        private

        def after_ingest
          each_pair do |occurrence_map, row|
            occurrence_map.component_id = row.first
          end
        end

        def attributes
          insertable_maps.map do |occurrence_map|
            occurrence_map.to_h.slice(*COMPONENT_ATTRIBUTES)
          end
        end
      end
    end
  end
end
