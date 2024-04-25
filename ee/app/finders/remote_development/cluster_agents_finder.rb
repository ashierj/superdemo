# frozen_string_literal: true

module RemoteDevelopment
  class ClusterAgentsFinder
    def self.execute(namespace:, filter:)
      case filter
      when :available
        relevant_mappings = RemoteDevelopmentNamespaceClusterAgentMapping.for_namespaces(namespace.traversal_ids)
        relevant_mappings = NamespaceClusterAgentMappings::Validations.filter_valid_namespace_cluster_agent_mappings(
          namespace_cluster_agent_mappings: relevant_mappings
        )

        Clusters::Agent.id_in(relevant_mappings.map(&:cluster_agent_id)).with_remote_development_enabled
      else
        raise "Unsupported value for filter: #{filter}"
      end
    end
  end
end
