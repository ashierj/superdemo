# frozen_string_literal: true

module Sbom
  module Ingestion
    class OccurrenceMap
      include Gitlab::Utils::StrongMemoize

      attr_reader :report_component, :report_source, :vulnerabilities
      attr_accessor :component_id, :component_version_id, :source_id, :occurrence_id, :source_package_id

      def initialize(report_component, report_source, vulnerabilities)
        @report_component = report_component
        @report_source = report_source
        @vulnerabilities = vulnerabilities
      end

      def to_h
        {
          component_id: component_id,
          component_version_id: component_version_id,
          component_type: report_component.component_type,
          name: report_component.name,
          purl_type: purl_type,
          source_id: source_id, source_type: report_source&.source_type,
          source: report_source&.data,
          source_package_id: source_package_id,
          source_package_name: report_component.source_package_name,
          version: version
        }
      end

      def version_present?
        version.present?
      end

      def vulnerability_count
        vulnerability_ids.count
      end

      def highest_severity
        vulnerabilities_info[:highest_severity]
      end

      def vulnerability_ids
        vulnerabilities_info[:vulnerability_ids]
      end
      strong_memoize_attr :vulnerability_ids

      def purl_type
        report_component.purl&.type
      end

      def packager
        report_component&.properties&.packager || report_source&.packager
      end

      def input_file_path
        return image_ref if container_scanning_component? && image_data_present?

        report_source&.input_file_path
      end

      delegate :image_name, :image_tag, to: :report_source, allow_nil: true
      delegate :name, :version, :source_package_name, to: :report_component

      private

      def vulnerabilities_info
        package_name = if container_scanning_component?
                         report_component.name_without_namespace
                       else
                         name
                       end

        @vulnerabilities.fetch(package_name, version, input_file_path)
      end
      strong_memoize_attr :vulnerabilities_info

      def image_data_present?
        image_name.present? && image_tag.present?
      end

      def container_scanning_component?
        report_component.properties&.source_type&.to_sym == :trivy
      end

      def image_ref
        "container-image:#{image_name}:#{image_tag}"
      end
    end
  end
end
