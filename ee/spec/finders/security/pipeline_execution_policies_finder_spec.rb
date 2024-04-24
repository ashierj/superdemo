# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Security::PipelineExecutionPoliciesFinder, feature_category: :security_policy_management do
  let!(:policy) { build(:pipeline_execution_policy, name: 'Contains custom pipeline configuration') }
  let!(:policy_yaml) do
    build(:orchestration_policy_yaml, pipeline_execution_policy: [policy])
  end

  include_context 'with scan policies information'

  it_behaves_like 'scan policies finder'
end
