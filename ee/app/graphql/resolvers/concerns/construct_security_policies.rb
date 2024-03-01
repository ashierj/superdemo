# frozen_string_literal: true

module ConstructSecurityPolicies
  extend ActiveSupport::Concern

  POLICY_YAML_ATTRIBUTES = %i[name description enabled actions rules approval_settings policy_scope].freeze

  def construct_scan_execution_policies(policies)
    policies.map do |policy|
      {
        name: policy[:name],
        description: policy[:description],
        edit_path: edit_path(policy, :scan_execution_policy),
        enabled: policy[:enabled],
        yaml: YAML.dump(policy.slice(*POLICY_YAML_ATTRIBUTES).deep_stringify_keys),
        updated_at: policy[:config].policy_last_updated_at,
        source: {
          project: policy[:project],
          namespace: policy[:namespace],
          inherited: policy[:inherited]
        }
      }
    end
  end

  def construct_scan_result_policies(policies)
    policies.map do |policy|
      approvers = approvers(policy)
      {
        name: policy[:name],
        description: policy[:description],
        edit_path: edit_path(policy, :approval_policy),
        enabled: policy[:enabled],
        yaml: YAML.dump(policy.slice(*POLICY_YAML_ATTRIBUTES).deep_stringify_keys),
        updated_at: policy[:config].policy_last_updated_at,
        user_approvers: approvers[:users],
        group_approvers: approvers[:groups],
        all_group_approvers: approvers[:all_groups],
        role_approvers: approvers[:roles],
        source: {
          project: policy[:project],
          namespace: policy[:namespace],
          inherited: policy[:inherited]
        }
      }
    end
  end

  def approvers(policy)
    Security::SecurityOrchestrationPolicies::FetchPolicyApproversService
      .new(policy: policy, container: object, current_user: current_user)
      .execute
  end

  def edit_path(policy, type)
    id = CGI.escape(policy[:name])
    if policy[:namespace]
      Rails.application.routes.url_helpers.edit_group_security_policy_url(
        policy[:namespace], id: id, type: type
      )
    else
      Rails.application.routes.url_helpers.edit_project_security_policy_url(
        policy[:project], id: id, type: type
      )
    end
  end
end
