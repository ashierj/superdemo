# frozen_string_literal: true

module Security
  module SecurityOrchestrationPolicies
    class UpdateViolationsService
      attr_reader :merge_request,
        :violated_rules,
        :unviolated_rules,
        :violations

      def initialize(merge_request)
        @merge_request = merge_request
        @violated_rules = []
      end

      def add(rules)
        violated_rules.concat(rules)
      end

      def execute
        return violated_rules.clear unless Feature.enabled?(:scan_result_any_merge_request, merge_request.project)

        Security::ScanResultPolicyViolation.transaction do
          delete_violations
          create_violations if violated_rules.any?
        end

        violated_rules.clear
      end

      # rubocop: disable CodeReuse/ActiveRecord
      def delete_violations
        Security::ScanResultPolicyViolation
          .where(merge_request_id: merge_request.id)
          .each_batch(order_hint: :updated_at) { |batch| batch.delete_all } # rubocop: disable Style/SymbolProc
      end
      # rubocop: enable CodeReuse/ActiveRecord

      # rubocop: disable CodeReuse/ActiveRecord
      def create_violations
        attrs = violated_rules.pluck(:scan_result_policy_id).map do |id|
          { scan_result_policy_id: id, merge_request_id: merge_request.id, project_id: merge_request.project_id }
        end

        Security::ScanResultPolicyViolation.insert_all(attrs) if attrs.any?
      end
      # rubocop: enable CodeReuse/ActiveRecord
    end
  end
end
