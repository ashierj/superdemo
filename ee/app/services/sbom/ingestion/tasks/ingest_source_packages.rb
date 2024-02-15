# frozen_string_literal: true

module Sbom
  module Ingestion
    module Tasks
      class IngestSourcePackages < Base
        include Gitlab::Ingestion::BulkInsertableTask

        SOURCE_PACKAGE_ATTRIBUTES = %i[name purl_type].freeze

        self.model = Sbom::SourcePackage
        self.unique_by = SOURCE_PACKAGE_ATTRIBUTES
        self.uses = ([:id] + SOURCE_PACKAGE_ATTRIBUTES).freeze

        private

        def after_ingest
          return_data.each do |source_package_id, source_package_name, purl_type|
            maps_with(source_package_name, purl_type)&.each do |occurrence_map|
              occurrence_map.source_package_id = source_package_id
            end
          end
        end

        def attributes
          valid_occurrence_maps.map do |occurrence_map|
            {
              name: occurrence_map.source_package_name,
              purl_type: occurrence_map.purl_type
            }
          end
        end

        def valid_occurrence_maps
          @valid_occurrence_maps ||= occurrence_maps.filter(&:source_package_name)
        end

        def maps_with(source_package_name, purl_type)
          grouped_maps[[source_package_name, purl_type]]
        end

        def grouped_maps
          @grouped_maps ||= valid_occurrence_maps.group_by do |occurrence_map|
            report_component = occurrence_map.report_component

            [report_component.source_package_name, report_component.purl_type]
          end
        end
      end
    end
  end
end
