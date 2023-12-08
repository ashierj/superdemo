# frozen_string_literal: true

module Sbom
  module Ingestion
    class OccurrenceMap
      include Gitlab::Utils::StrongMemoize

      attr_reader :report_component, :report_source, :vulnerabilities
      attr_accessor :component_id, :component_version_id, :source_id, :occurrence_id

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
          source_id: source_id,
          source_type: report_source&.source_type,
          source: report_source&.data,
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

      delegate :packager, :input_file_path, to: :report_source, allow_nil: true
      delegate :name, :version, to: :report_component

      private

      def purl_type
        report_component.purl&.type
      end

      def vulnerabilities_info
        @vulnerabilities.fetch(name, version, input_file_path)
      end
      strong_memoize_attr :vulnerabilities_info
    end
  end
end
