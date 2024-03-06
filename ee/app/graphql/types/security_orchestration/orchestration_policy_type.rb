# frozen_string_literal: true

module Types
  module SecurityOrchestration
    module OrchestrationPolicyType
      include Types::BaseInterface

      field :description, GraphQL::Types::String, null: false, description: 'Description of the policy.'
      field :edit_path, GraphQL::Types::String, null: false, description: 'URL of policy edit page.'
      field :enabled, GraphQL::Types::Boolean, null: false, description: 'Indicates whether this policy is enabled.'
      field :name, GraphQL::Types::String, null: false, description: 'Name of the policy.'
      field :updated_at, Types::TimeType, null: false, description: 'Timestamp of when the policy YAML was last updated.'
      field :yaml, GraphQL::Types::String, null: false, description: 'YAML definition of the policy.'
      field :policy_scope, ::Types::SecurityOrchestration::PolicyScopeType,
        null: true,
        alpha: { milestone: '16.10' },
        description: 'Scope of the policy. Returns `null` if Security Policy Scope experimental feature is disabled.'
    end
  end
end
