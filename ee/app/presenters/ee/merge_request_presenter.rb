# frozen_string_literal: true

module EE
  module MergeRequestPresenter
    extend ::Gitlab::Utils::Override
    extend ::Gitlab::Utils::DelegatorOverride

    APPROVALS_WIDGET_FULL_TYPE = 'full'

    def api_approval_settings_path
      if expose_mr_approval_path?
        expose_path(api_v4_projects_merge_requests_approval_settings_path(id: project.id, merge_request_iid: merge_request.iid))
      end
    end

    def api_project_approval_settings_path
      if approval_feature_available?
        expose_path(api_v4_projects_approval_settings_path(id: project.id))
      end
    end

    def api_status_checks_path
      if expose_mr_status_checks?
        expose_path(api_v4_projects_merge_requests_status_checks_path(id: project.id, merge_request_iid: merge_request.iid))
      end
    end

    def merge_immediately_docs_path
      help_page_path('ci/pipelines/merge_trains', anchor: 'immediately-merge-a-merge-request-with-a-merge-train')
    end

    delegator_override :target_project
    def target_project
      merge_request.target_project.present(current_user: current_user)
    end

    def code_owner_rules_with_users
      @code_owner_rules ||= merge_request.approval_rules.code_owner.with_users.to_a
    end

    delegator_override :approver_groups
    def approver_groups
      ::ApproverGroup.filtered_approver_groups(merge_request.approver_groups, current_user)
    end

    def suggested_approvers
      merge_request.approval_state.suggested_approvers(current_user: current_user)
    end

    override :approvals_widget_type
    def approvals_widget_type
      expose_mr_approval_path? ? APPROVALS_WIDGET_FULL_TYPE : super
    end

    def discover_project_security_path
      project_security_discover_path(project) if show_discover_project_security?(project)
    end

    def issue_keys
      return [] unless project.jira_integration.try(:active?)

      Atlassian::JiraIssueKeyExtractor.new(
        merge_request.title,
        merge_request.description,
        custom_regex: project.jira_integration.reference_pattern
      ).issue_keys
    end

    def saml_approval_path
      return unless feature_flag_for_saml_auth_to_approve_enabled?
      return unless group.is_a?(Group) # feature does not work for personal namespaces

      return unless group_requires_saml_auth_for_approval?

      expose_path sso_group_saml_providers_path(
        root_group,
        token: root_group.saml_discovery_token,
        redirect: saml_approval_redirect_path
      )
    end

    def require_saml_auth_to_approve
      return false unless feature_flag_for_saml_auth_to_approve_enabled?

      group_requires_saml_auth_for_approval?
    end

    private

    def feature_flag_for_saml_auth_to_approve_enabled?
      root_group && ::Feature.enabled?(:ff_require_saml_auth_to_approve, root_group)
    end

    def root_group
      group.root_ancestor
    end

    def group
      target_project.namespace
    end

    def group_requires_saml_auth_for_approval?
      return false unless mr_approval_setting_password_required?

      # we are intentionally passing the project as a resource here
      ::Gitlab::Auth::GroupSaml::SsoEnforcer.access_restricted?(
        user: current_user,
        resource: merge_request.project,
        session_timeout: 0.seconds
      )
    end

    def mr_approval_setting_password_required?
      merge_request.require_password_to_approve?
    end

    def saml_approval_redirect_path
      # Will not work with URL since the SSO controller will sanatize it
      saml_approval_namespace_project_merge_request_path(group, target_project, merge_request.iid)
    end

    def expose_mr_status_checks?
      current_user.present? &&
        project.external_status_checks.applicable_to_branch(merge_request.target_branch).any?
    end

    def expose_mr_approval_path?
      approval_feature_available? && merge_request.iid
    end
  end
end

EE::MergeRequestPresenter.include_mod_with('ProjectsHelper')
