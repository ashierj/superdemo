# frozen_string_literal: true

module RemoteDevelopment
  module Workspaces
    module Reconcile
      module Input
        class ParamsToInfosConverter
          include Messages

          # @param [Hash] value
          # @return [Hash]
          def self.convert(value)
            value => { workspace_agent_info_hashes_from_params: Array => workspace_agent_info_hashes_from_params }

            # Convert the workspace_agent_info_hashes_from_params array into an array of AgentInfo objects
            workspace_agent_infos_by_name =
              workspace_agent_info_hashes_from_params.each_with_object({}) do |agent_info_hash_from_params, hash|
                agent_info = Factory.build(agent_info_hash_from_params: agent_info_hash_from_params)
                hash[agent_info.name.to_sym] = agent_info
              end

            value.merge(workspace_agent_infos_by_name: workspace_agent_infos_by_name)
          end
        end
      end
    end
  end
end
