# frozen_string_literal: true

module Sbom
  module Ingestion
    class Vulnerabilities
      include Gitlab::Utils::StrongMemoize

      attr_reader :pipeline, :vulnerabilities_info

      delegate :project, to: :pipeline

      def initialize(pipeline)
        @pipeline = pipeline
      end

      def fetch(name, version, path)
        update_vulnerabilities_info unless vulnerabilities_info

        key = [name, version, path]
        if vulnerabilities_info.has_key?(key)
          vulnerabilities_info[key]
        else
          { vulnerability_ids: [], highest_severity: nil }
        end
      end

      private

      def update_vulnerabilities_info
        @vulnerabilities_info = {}

        vulnerability_findings.each do |finding|
          dependency = finding.location["dependency"]

          next unless dependency

          key = [dependency['package']['name'], dependency['version'], dependency_path(finding)]
          if vulnerabilities_info.has_key?(key)
            @vulnerabilities_info[key][:vulnerability_ids] << finding.vulnerability_id
          else
            @vulnerabilities_info[key] = {
              vulnerability_ids: [finding.vulnerability_id],
              highest_severity: finding.severity
            }
          end
        end
      end

      def vulnerability_findings
        pipeline
          .vulnerability_findings
          .by_report_types(%i[container_scanning dependency_scanning])
          .ordered
      end
      strong_memoize_attr :vulnerability_findings

      def dependency_path(finding)
        return finding.file if finding.dependency_scanning?

        "#{Gitlab::Ci::Parsers::Security::DependencyList::CONTAINER_IMAGE_PATH_PREFIX}#{finding.image}"
      end
    end
  end
end
