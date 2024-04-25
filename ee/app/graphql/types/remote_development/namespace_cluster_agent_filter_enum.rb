# frozen_string_literal: true

module Types
  module RemoteDevelopment
    class NamespaceClusterAgentFilterEnum < BaseEnum
      graphql_name 'NamespaceClusterAgentFilter'
      description 'Possible filter types for remote development cluster agents in a namespace'

      value 'AVAILABLE',
        description: "Cluster agents in the namespace that can be used for hosting workspaces.", value: 'AVAILABLE'
    end
  end
end
