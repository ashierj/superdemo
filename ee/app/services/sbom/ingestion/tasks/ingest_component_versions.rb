# frozen_string_literal: true

module Sbom
  module Ingestion
    module Tasks
      class IngestComponentVersions < Base
        COMPONENT_VERSION_ATTRIBUTES = %i[component_id version].freeze

        self.model = Sbom::ComponentVersion
        self.unique_by = COMPONENT_VERSION_ATTRIBUTES
        self.uses = %i[id component_id version].freeze

        private

        def after_ingest
          each_pair do |occurrence_map, row|
            occurrence_map.component_version_id = row.first
          end
        end

        def attributes
          insertable_maps.map do |occurrence_map|
            occurrence_map.to_h.slice(*COMPONENT_VERSION_ATTRIBUTES)
          end
        end

        def insertable_maps
          super.filter(&:version_present?)
        end
      end
    end
  end
end
