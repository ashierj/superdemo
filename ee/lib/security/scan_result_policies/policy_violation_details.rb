# frozen_string_literal: true

module Security
  module ScanResultPolicies
    class PolicyViolationDetails
      include Gitlab::Utils::StrongMemoize

      Violation = Struct.new(:report_type, :name, :scan_result_policy_id, :data, keyword_init: true)
      ScanFindingViolation = Struct.new(:name, :report_type, :severity, :location, :path, keyword_init: true)
      AnyMergeRequestViolation = Struct.new(:name, :commits, keyword_init: true)

      def initialize(merge_request)
        @merge_request = merge_request
      end

      def violations
        merge_request.scan_result_policy_violations.map do |violation|
          rule = scan_result_policy_rules[violation.scan_result_policy_id]
          Violation.new(
            report_type: rule.report_type,
            name: rule.name,
            scan_result_policy_id: rule.scan_result_policy_id,
            data: violation.violation_data
          )
        end
      end
      strong_memoize_attr :violations

      def new_scan_finding_violations
        new_uuids = violations.each_with_object(Set.new) do |violation, result|
          result.merge(violation.data&.dig('violations', 'scan_finding', 'uuids', 'newly_detected') || [])
        end
        pipeline_ids = violations.each_with_object(Set.new) do |violation, result|
          result.merge(violation.data&.dig('context', 'pipeline_ids') || [])
        end

        newly_detected_violations(new_uuids, pipeline_ids)
      end
      strong_memoize_attr :new_scan_finding_violations

      def previous_scan_finding_violations
        uuids = violations.each_with_object(Set.new) do |violation, result|
          result.merge(violation.data&.dig('violations', 'scan_finding', 'uuids', 'previously_existing') || [])
        end
        previously_existing_violations(uuids)
      end
      strong_memoize_attr :previous_scan_finding_violations

      def any_merge_request_violations
        violations.select { |violation| violation.report_type == 'any_merge_request' }.flat_map do |violation|
          AnyMergeRequestViolation.new(
            name: violation.name,
            commits: violation.data&.dig('violations', 'any_merge_request', 'commits')
          )
        end
      end
      strong_memoize_attr :any_merge_request_violations

      private

      attr_accessor :merge_request

      delegate :project, to: :merge_request

      def pipeline
        merge_request.diff_head_pipeline
      end
      strong_memoize_attr :pipeline

      def scan_result_policy_rules
        merge_request.approval_rules.with_scan_result_policy_read.index_by(&:scan_result_policy_id)
      end
      strong_memoize_attr :scan_result_policy_rules

      def previously_existing_violations(uuids)
        return [] if uuids.blank?

        Security::ScanResultPolicies::VulnerabilitiesFinder.new(project,
          { limit: uuids_limit, uuids: uuids.first(uuids_limit) }).execute.map do |vulnerability|
          finding = vulnerability.finding
          ScanFindingViolation.new(
            report_type: finding.report_type,
            severity: finding.severity,
            path: vulnerability.present.location_link,
            location: finding.location.with_indifferent_access,
            name: finding.name
          )
        end
      end

      def newly_detected_violations(uuids, related_pipeline_ids)
        return [] if uuids.blank?

        Security::ScanResultPolicies::FindingsFinder.new(project, pipeline,
          { related_pipeline_ids: related_pipeline_ids, uuids: uuids.first(uuids_limit) }).execute.map do |finding|
          ScanFindingViolation.new(
            report_type: finding.report_type,
            severity: finding.severity,
            path: finding.present.blob_url,
            location: finding.location.with_indifferent_access,
            name: finding.name
          )
        end
      end

      def uuids_limit
        Security::ScanResultPolicyViolation::MAX_VIOLATIONS + 1
      end
    end
  end
end
