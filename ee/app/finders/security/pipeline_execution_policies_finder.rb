# frozen_string_literal: true

module Security
  class PipelineExecutionPoliciesFinder < ScanPolicyBaseFinder
    extend ::Gitlab::Utils::Override

    def initialize(actor, object, params = {})
      super(actor, object, :pipeline_execution_policy, params)
    end

    def execute
      fetch_scan_policies
    end
  end
end
