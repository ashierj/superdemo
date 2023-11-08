# frozen_string_literal: true

module ComplianceManagement
  module ComplianceFramework
    class SecurityPolicy < ApplicationRecord
      self.table_name = 'compliance_framework_security_policies'

      belongs_to :policy_configuration, class_name: 'Security::OrchestrationPolicyConfiguration'
      belongs_to :framework, class_name: 'ComplianceManagement::Framework'

      validates :framework, uniqueness: { scope: [:policy_configuration_id, :policy_index] }

      scope :for_framework, ->(framework) { where(framework: framework) }
      scope :for_policy_configuration, ->(policy_configuration) { where(policy_configuration: policy_configuration) }
    end
  end
end
