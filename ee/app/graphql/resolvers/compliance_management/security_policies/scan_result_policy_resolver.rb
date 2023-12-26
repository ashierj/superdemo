# frozen_string_literal: true

module Resolvers
  module ComplianceManagement
    module SecurityPolicies
      class ScanResultPolicyResolver < BaseResolver
        include ResolvesOrchestrationPolicy

        type Types::SecurityOrchestration::ScanResultPolicyType, null: true

        def resolve
          ::Gitlab::Graphql::Aggregations::SecurityOrchestrationPolicies::LazyComplianceFrameworkAggregate.new(
            context, object, :scan_result_policies
          )
        end
      end
    end
  end
end
