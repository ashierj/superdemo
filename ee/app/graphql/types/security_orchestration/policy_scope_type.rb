# frozen_string_literal: true

module Types
  module SecurityOrchestration
    class PolicyScopeType < BaseObject # rubocop:disable Graphql/AuthorizeTypes -- This is a read from policy YAML
      graphql_name 'PolicyScope'

      authorize []

      field :compliance_frameworks, ::Types::ComplianceManagement::ComplianceFrameworkType.connection_type,
        null: false,
        description: 'Compliance Frameworks linked to the policy.'

      field :including_projects, ::Types::ProjectType.connection_type,
        null: false,
        description: 'Projects to which the policy should be applied to.'

      field :excluding_projects, ::Types::ProjectType.connection_type,
        null: false,
        description: 'Projects to which the policy should not be applied to.'
    end
  end
end
