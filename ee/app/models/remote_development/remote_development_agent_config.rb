# frozen_string_literal: true

module RemoteDevelopment
  # noinspection RailsParamDefResolve - https://handbook.gitlab.com/handbook/tools-and-tips/editors-and-ides/jetbrains-ides/tracked-jetbrains-issues/#ruby-31540
  class RemoteDevelopmentAgentConfig < ApplicationRecord
    # NOTE: See the following comment for the reasoning behind the `RemoteDevelopment` prefix of this table/model:
    #       https://gitlab.com/gitlab-org/gitlab/-/issues/410045#note_1385602915
    include IgnorableColumns

    ignore_column :max_workspaces, remove_with: '16.8', remove_after: '2023-12-22'
    ignore_column :max_workspaces_per_user, remove_with: '16.8', remove_after: '2023-12-22'

    belongs_to :agent,
      class_name: 'Clusters::Agent', foreign_key: 'cluster_agent_id', inverse_of: :remote_development_agent_config

    has_many :workspaces, through: :agent, source: :workspaces

    validates :agent, presence: true
    validates :dns_zone, hostname: true
    validates :enabled, inclusion: { in: [true, false] }

    validates :network_policy_egress,
      json_schema: { filename: 'remote_development_agent_configs_network_policy_egress' }
    validates :network_policy_egress, 'remote_development/network_policy_egress': true
    validates :default_resources_per_workspace_container,
      json_schema: { filename: 'remote_development_agent_configs_workspace_container_resources' }
    validates :default_resources_per_workspace_container, 'remote_development/workspace_container_resources': true
    validates :max_resources_per_workspace,
      json_schema: { filename: 'remote_development_agent_configs_workspace_container_resources' }
    validates :max_resources_per_workspace, 'remote_development/workspace_container_resources': true

    # noinspection RubyResolve - likely due to https://handbook.gitlab.com/handbook/tools-and-tips/editors-and-ides/jetbrains-ides/tracked-jetbrains-issues/#ruby-31540
    before_validation :prevent_dns_zone_update, if: ->(record) { record.persisted? && record.dns_zone_changed? }

    private

    def prevent_dns_zone_update
      errors.add(:dns_zone, _('is currently immutable, and cannot be updated. Create a new agent instead.'))
    end
  end
end
