# frozen_string_literal: true

module Resolvers
  module Kas
    class AgentConnectionsResolver < BaseResolver
      type Types::Kas::AgentConnectionType, null: true

      alias_method :agent, :object

      delegate :project, to: :agent

      def resolve
        return [] unless can_read_connected_agents?

        BatchLoader::GraphQL.for(agent.id).batch(key: project, default_value: []) do |agent_ids, loader|
          agents = get_connected_agents.group_by(&:agent_id).slice(*agent_ids)

          agents.each do |agent_id, connections|
            loader.call(agent_id, connections)
          end
        end
      end

      private

      def can_read_connected_agents?
        project.licensed_feature_available?(:cluster_agents) && current_user.can?(:admin_cluster, project)
      end

      def get_connected_agents
        kas_client.get_connected_agents(project: project)
      rescue GRPC::BadStatus => e
        raise Gitlab::Graphql::Errors::ResourceNotAvailable, e.class.name
      end

      def kas_client
        @kas_client ||= Gitlab::Kas::Client.new
      end
    end
  end
end
