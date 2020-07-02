# frozen_string_literal: true

module Types
  class InstanceSecurityDashboardType < BaseObject
    graphql_name 'InstanceSecurityDashboard'

    authorize :read_instance_security_dashboard

    field :projects,
          Types::ProjectType.connection_type,
          null: false,
          authorize: :read_project,
          description: 'Projects selected in Instance Security Dashboard'

    field :vulnerability_scanners,
          ::Types::VulnerabilityScannerType.connection_type,
          null: true,
          description: 'Vulnerability scanners reported on the vulnerabilties from projects selected in Instance Security Dashboard',
          resolver: ::Resolvers::Vulnerabilities::ScannersResolver
  end
end
