# frozen_string_literal: true

FactoryBot.define do
  factory :scan_result_policy_violation, class: 'Security::ScanResultPolicyViolation' do
    project
    merge_request
    scan_result_policy_read
    violation_data { { "violations" => { "any_merge_request" => { "commits" => ["f89a4ed7"] } } } }
  end
end
