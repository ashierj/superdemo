# frozen_string_literal: true

module EE
  module ProjectPolicy
    extend ActiveSupport::Concern
    extend ::Gitlab::Utils::Override

    prepended do
      include ReadonlyAbilities

      desc "User is a security policy bot on the project"
      condition(:security_policy_bot) { user&.security_policy_bot? && team_member? }

      with_scope :subject
      condition(:auto_fix_enabled) { @subject.security_setting&.auto_fix_enabled? }

      with_scope :subject
      condition(:repository_mirrors_enabled) { @subject.feature_available?(:repository_mirrors) }

      with_scope :subject
      condition(:iterations_available) { @subject.group&.licensed_feature_available?(:iterations) }

      with_scope :subject
      condition(:requirements_available) { @subject.feature_available?(:requirements) & access_allowed_to?(:requirements) }

      with_scope :subject
      condition(:quality_management_available) { @subject.feature_available?(:quality_management) }

      condition(:compliance_framework_available) { @subject.feature_available?(:compliance_framework, @user) }

      with_scope :global
      condition(:is_development) { Rails.env.development? }

      with_scope :global
      condition(:locked_approvers_rules) do
        !@user.can_admin_all_resources? &&
          License.feature_available?(:admin_merge_request_approvers_rules) &&
          ::Gitlab::CurrentSettings.disable_overriding_approvers_per_merge_request
      end

      condition(:group_merge_request_approval_settings_enabled) do
        @subject.feature_available?(:merge_request_approvers)
      end

      with_scope :global
      condition(:locked_merge_request_author_setting) do
        License.feature_available?(:admin_merge_request_approvers_rules) &&
          ::Gitlab::CurrentSettings.prevent_merge_requests_author_approval
      end

      with_scope :global
      condition(:locked_merge_request_committer_setting) do
        License.feature_available?(:admin_merge_request_approvers_rules) &&
          ::Gitlab::CurrentSettings.prevent_merge_requests_committers_approval
      end

      with_scope :subject
      condition(:dora4_analytics_available) do
        @subject.feature_available?(:dora4_analytics)
      end

      condition(:project_merge_request_analytics_available) do
        @subject.feature_available?(:project_merge_request_analytics)
      end

      with_scope :subject
      condition(:group_push_rules_enabled) do
        @subject.group && @subject.group.licensed_feature_available?(:push_rules)
      end

      with_scope :subject
      condition(:group_push_rule_present) do
        group_push_rules_enabled? && subject.group.push_rule
      end

      with_scope :subject
      condition(:commit_committer_check_available) do
        @subject.feature_available?(:commit_committer_check)
      end

      with_scope :subject
      condition(:commit_committer_name_check_available) do
        @subject.feature_available?(:commit_committer_name_check)
      end

      with_scope :subject
      condition(:reject_unsigned_commits_available) do
        @subject.feature_available?(:reject_unsigned_commits)
      end

      with_scope :subject
      condition(:reject_non_dco_commits_available) do
        @subject.feature_available?(:reject_non_dco_commits)
      end

      with_scope :subject
      condition(:security_orchestration_policies_enabled) do
        @subject.feature_available?(:security_orchestration_policies)
      end

      with_scope :subject
      condition(:security_dashboard_enabled) do
        @subject.feature_available?(:security_dashboard)
      end

      with_scope :subject
      condition(:coverage_fuzzing_enabled) do
        @subject.feature_available?(:coverage_fuzzing)
      end

      with_scope :subject
      condition(:on_demand_scans_enabled) do
        @subject.feature_available?(:security_on_demand_scans) &&
          !::Gitlab::FIPS.enabled?
      end

      with_scope :subject
      condition(:license_scanning_enabled) do
        @subject.feature_available?(:license_scanning)
      end

      with_scope :subject
      condition(:dependency_scanning_enabled) do
        @subject.feature_available?(:dependency_scanning)
      end

      with_scope :subject
      condition(:code_review_analytics_enabled) do
        @subject.feature_available?(:code_review_analytics, @user)
      end

      with_scope :subject
      condition(:issue_analytics_enabled) do
        @subject.feature_available?(:issues_analytics, @user)
      end

      with_scope :subject
      condition(:combined_project_analytics_dashboards_enabled) do
        @subject.feature_available?(:combined_project_analytics_dashboards, @user)
      end

      condition(:status_page_available) do
        @subject.feature_available?(:status_page, @user)
      end

      condition(:read_only, scope: :subject) do
        @subject.root_namespace.read_only?
      end

      with_scope :subject
      condition(:feature_flags_related_issues_disabled) do
        !@subject.feature_available?(:feature_flags_related_issues)
      end

      with_scope :subject
      condition(:oncall_schedules_available) do
        ::Gitlab::IncidentManagement.oncall_schedules_available?(@subject)
      end

      with_scope :subject
      condition(:escalation_policies_available) do
        ::Gitlab::IncidentManagement.escalation_policies_available?(@subject)
      end

      with_scope :subject
      condition(:hidden) do
        @subject.hidden?
      end

      with_scope :subject
      condition(:membership_locked_via_parent_group) do
        @subject.group && (
          @subject.group.membership_lock? ||
          ::Gitlab::CurrentSettings.lock_memberships_to_ldap? ||
          ::Gitlab::CurrentSettings.lock_memberships_to_saml)
      end

      with_scope :subject
      condition(:security_policy_project_available) do
        @subject.security_orchestration_policy_configuration.present?
      end

      with_scope :subject
      condition(:can_commit_to_security_policy_project) do
        security_orchestration_policy_configuration = @subject.security_orchestration_policy_configuration

        next unless security_orchestration_policy_configuration

        Ability.allowed?(@user, :developer_access, security_orchestration_policy_configuration.security_policy_management_project)
      end

      with_scope :subject
      condition(:okrs_enabled) do
        @subject.okrs_mvc_feature_flag_enabled? && @subject.feature_available?(:okrs)
      end

      with_scope :subject
      condition(:licensed_cycle_analytics_available, scope: :subject) do
        @subject.feature_available?(:cycle_analytics_for_projects)
      end

      condition(:user_banned_from_namespace) do
        next unless @user.is_a?(User)
        next if @user.can_admin_all_resources?
        # Loading the namespace_bans association is intentional because it is going to
        # be used in the banned_from_namespace? check below
        next if @user.namespace_bans.to_a.empty?

        groups = @subject.invited_groups + [@subject.group]
        groups.compact!
        next if groups.empty?

        groups.any? do |group|
          next unless group.root_ancestor.unique_project_download_limit_enabled?

          @user.banned_from_namespace?(group.root_ancestor)
        end
      end

      rule { membership_locked_via_parent_group }.policy do
        prevent :import_project_members_from_another_project
      end

      condition(:custom_roles_allowed) do
        @subject.custom_roles_enabled?
      end

      desc "Custom role on project that enables read code"
      condition(:role_enables_read_code) do
        ::Auth::MemberRoleAbilityLoader.new(
          user: @user,
          resource: @subject,
          ability: :read_code
        ).has_ability?
      end

      desc "Custom role on project that enables read vulnerability"
      condition(:role_enables_read_vulnerability) do
        ::Auth::MemberRoleAbilityLoader.new(
          user: @user,
          resource: @subject,
          ability: :read_vulnerability
        ).has_ability?
      end

      desc "Custom role on project that enables admin merge request"
      condition(:role_enables_admin_merge_request) do
        ::Auth::MemberRoleAbilityLoader.new(
          user: @user,
          resource: @subject,
          ability: :admin_merge_request
        ).has_ability?
      end

      desc "Custom role on project that enables admin vulnerability"
      condition(:role_enables_admin_vulnerability) do
        ::Auth::MemberRoleAbilityLoader.new(
          user: @user,
          resource: @subject,
          ability: :admin_vulnerability
        ).has_ability?
      end

      desc "Custom role on project that enables read dependency"
      condition(:role_enables_read_dependency) do
        ::Auth::MemberRoleAbilityLoader.new(
          user: @user,
          resource: @subject,
          ability: :read_dependency
        ).has_ability?
      end

      condition(:developer_access_to_admin_vulnerability) do
        ::Feature.disabled?(:disable_developer_access_to_admin_vulnerability, subject&.group) &&
          can?(:developer_access)
      end

      with_scope :subject
      condition(:suggested_reviewers_available) do
        @subject.can_suggest_reviewers?
      end

      with_scope :subject
      condition(:ai_features_enabled) do
        ::Feature.enabled?(:ai_global_switch, type: :ops)
      end

      with_scope :subject
      condition(:fill_in_merge_request_template_enabled) do
        ::Feature.enabled?(:fill_in_mr_template, subject) &&
          subject.licensed_feature_available?(:fill_in_merge_request_template) &&
          ::Gitlab::Llm::StageCheck.available?(subject, :fill_in_merge_request_template)
      end

      with_scope :subject
      condition(:generate_description_enabled) do
        ::Feature.enabled?(:ai_global_switch, type: :ops) &&
          subject.group&.licensed_feature_available?(:generate_description) &&
          ::Gitlab::Llm::StageCheck.available?(subject, :generate_description)
      end

      with_scope :subject
      condition(:target_branch_rules_available) { subject.licensed_feature_available?(:target_branch_rules) }

      with_scope :subject
      condition(:target_branch_rules_enabled) do
        ::Feature.enabled?(:target_branch_rules_flag, subject)
      end

      condition(:pages_multiple_versions_available) do
        ::Feature.enabled?(:pages_multiple_versions_setting, @subject) &&
          @subject.licensed_feature_available?(:pages_multiple_versions)
      end

      condition(:merge_requests_is_a_private_feature) do
        project.project_feature&.private?(:merge_requests)
      end

      condition(:tracing_enabled) do
        # Can be enabled for all projects in root namespace. Maintains backward
        # compatibility by falling back to checking against project
        (::Feature.enabled?(:observability_tracing,
          @subject.root_namespace) || ::Feature.enabled?(:observability_tracing, @subject)) &&
          @subject.licensed_feature_available?(:tracing)
      end

      condition(:observability_metrics_enabled) do
        ::Feature.enabled?(:observability_metrics, @subject.root_namespace) &&
          @subject.licensed_feature_available?(:metrics_observability)
      end

      # We are overriding the already defined condition in CE version
      # to allow Guest users with member roles to access the merge requests.
      condition(:merge_requests_disabled) do
        !(access_allowed_to?(:merge_requests) ||
          (custom_roles_allowed? && merge_requests_is_a_private_feature? && role_enables_admin_merge_request?))
      end

      condition(:ci_cancellation_maintainers_only, scope: :subject) do
        project.ci_cancellation_restriction.maintainers_only_allowed?
      end

      condition(:ci_cancellation_no_one, scope: :subject) do
        project.ci_cancellation_restriction.no_one_allowed?
      end

      rule { visual_review_bot }.policy do
        prevent :read_note
        enable :create_note
      end

      rule { license_block }.policy do
        prevent :create_issue
        prevent :create_merge_request_in
        prevent :create_merge_request_from
        prevent :push_code
      end

      rule { analytics_disabled }.policy do
        prevent(:read_project_merge_request_analytics)
        prevent(:read_code_review_analytics)
        prevent(:read_issue_analytics)
      end

      rule { feature_flags_related_issues_disabled | repository_disabled }.policy do
        prevent :admin_feature_flags_issue_links
      end

      rule { can?(:guest_access) & iterations_available }.enable :read_iteration

      rule { can?(:reporter_access) }.policy do
        enable :admin_issue_board
      end

      rule { monitor_disabled }.policy do
        prevent :read_incident_management_oncall_schedule
        prevent :admin_incident_management_oncall_schedule
        prevent :read_incident_management_escalation_policy
        prevent :admin_incident_management_escalation_policy
      end

      rule { oncall_schedules_available & can?(:reporter_access) }.enable :read_incident_management_oncall_schedule
      rule { escalation_policies_available & can?(:reporter_access) }.enable :read_incident_management_escalation_policy

      rule { can?(:developer_access) }.policy do
        enable :admin_issue_board
        enable :read_vulnerability_feedback
        enable :create_vulnerability_feedback
        enable :destroy_vulnerability_feedback
        enable :update_vulnerability_feedback
        enable :admin_feature_flags_issue_links
        enable :read_project_audit_events
        enable :read_product_analytics
        enable :create_workspace
      end

      rule { can?(:reporter_access) & iterations_available }.policy do
        enable :create_iteration
        enable :admin_iteration
      end

      rule { can?(:read_project) & iterations_available }.enable :read_iteration

      rule { security_orchestration_policies_enabled & can?(:developer_access) }.policy do
        enable :read_security_orchestration_policies
      end

      rule { security_orchestration_policies_enabled & can?(:owner_access) }.policy do
        enable :update_security_orchestration_policy_project
      end

      rule { security_orchestration_policies_enabled & can?(:guest_access) }.policy do
        enable :read_security_orchestration_policy_project
      end

      rule { security_orchestration_policies_enabled & auditor }.policy do
        enable :read_security_orchestration_policies
      end

      rule { security_orchestration_policies_enabled & can?(:owner_access) & ~security_policy_project_available }.policy do
        enable :modify_security_policy
      end

      rule { security_orchestration_policies_enabled & security_policy_project_available & can_commit_to_security_policy_project }.policy do
        enable :modify_security_policy
      end

      rule { security_dashboard_enabled & can?(:developer_access) }.policy do
        enable :read_security_resource
        enable :read_vulnerability_scanner
      end

      rule { coverage_fuzzing_enabled & can?(:developer_access) }.policy do
        enable :read_coverage_fuzzing
        enable :create_coverage_fuzzing_corpus
      end

      rule { on_demand_scans_enabled & can?(:developer_access) }.policy do
        enable :read_on_demand_dast_scan
        enable :create_on_demand_dast_scan
        enable :edit_on_demand_dast_scan
      end

      # If licensed but not reporter+, prevent access
      rule { (~reporter & ~auditor & ~admin) & licensed_cycle_analytics_available }.policy do
        prevent :read_cycle_analytics
      end

      # If licensed and reporter+, allow access
      rule { (reporter | admin) & licensed_cycle_analytics_available }.policy do
        enable :read_cycle_analytics
        enable :admin_value_stream
      end

      rule { can?(:read_merge_request) & can?(:read_pipeline) }.enable :read_merge_train

      rule { can?(:read_security_resource) }.policy do
        enable :read_project_security_dashboard
        enable :create_vulnerability_export
        enable :admin_vulnerability_issue_link
        enable :admin_vulnerability_merge_request_link
        enable :admin_vulnerability_external_issue_link
      end

      rule { can?(:read_security_resource) }.policy do
        enable :read_vulnerability
      end

      rule { can?(:read_security_resource) & (can?(:maintainer_access) | developer_access_to_admin_vulnerability) }.policy do
        enable :admin_vulnerability
      end

      rule { security_and_compliance_disabled }.policy do
        prevent :admin_vulnerability
        prevent :read_vulnerability
      end

      rule { security_bot & auto_fix_enabled }.policy do
        enable :push_code
        enable :create_merge_request_from
        enable :create_vulnerability_feedback
        enable :admin_merge_request
      end

      rule { issues_disabled }.policy do
        prevent :read_issue_analytics
      end

      rule { merge_requests_disabled }.policy do
        prevent :read_project_merge_request_analytics
      end

      rule { issues_disabled & merge_requests_disabled }.policy do
        prevent(*create_read_update_admin_destroy(:iteration))
      end

      rule { dependency_scanning_enabled & can?(:download_code) }.enable :read_dependency

      rule { license_scanning_enabled & can?(:download_code) }.enable :read_licenses

      rule { can?(:read_licenses) }.enable :read_software_license_policy

      rule { repository_mirrors_enabled & ((mirror_available & can?(:admin_project)) | admin) }.enable :admin_mirror

      rule { can?(:maintainer_access) }.policy do
        enable :push_code_to_protected_branches
        enable :admin_path_locks
        enable :read_approvers
        enable :update_approvers
        enable :modify_approvers_rules
        enable :modify_auto_fix_setting
        enable :modify_merge_request_author_setting
        enable :modify_merge_request_committer_setting
        enable :modify_product_analytics_settings
      end

      rule { license_scanning_enabled & can?(:maintainer_access) }.enable :admin_software_license_policy

      rule { oncall_schedules_available & can?(:maintainer_access) }.enable :admin_incident_management_oncall_schedule
      rule { escalation_policies_available & can?(:maintainer_access) }.enable :admin_incident_management_escalation_policy

      rule { auditor }.policy do
        enable :public_user_access
        prevent :request_access

        enable :read_build
        enable :read_environment
        enable :read_deployment
        enable :read_pages
        enable :read_project_audit_events
        enable :read_cluster
        enable :read_terraform_state
        enable :read_project_merge_request_analytics
        enable :read_approvers
        enable :read_on_demand_dast_scan

        enable :read_project_runners
      end

      rule { auditor & ~guest & private_project }.policy do
        prevent :fork_project
        prevent :create_merge_request_in
      end

      rule { auditor }.policy do
        enable :access_security_and_compliance
      end

      rule { auditor & security_dashboard_enabled }.policy do
        enable :read_security_resource
        enable :read_vulnerability_scanner
      end

      rule { auditor & oncall_schedules_available }.policy do
        enable :read_incident_management_oncall_schedule
      end

      rule { auditor & escalation_policies_available }.policy do
        enable :read_incident_management_escalation_policy
      end

      rule { auditor & ~monitor_disabled }.policy do
        enable :read_alert_management_alert
      end

      rule { auditor & ~developer }.policy do
        prevent :admin_vulnerability_issue_link
        prevent :admin_vulnerability_external_issue_link
        prevent :admin_vulnerability_merge_request_link
        prevent :admin_vulnerability
      end

      rule { auditor & ~guest }.policy do
        prevent :create_project
        prevent :create_issue
        prevent :create_note
        prevent :upload_file
      end

      rule { ~can?(:push_code) }.prevent :push_code_to_protected_branches

      rule { admin | maintainer }.enable :change_reject_unsigned_commits

      rule { reject_unsigned_commits_available }.enable :read_reject_unsigned_commits

      rule { ~reject_unsigned_commits_available }.prevent :change_reject_unsigned_commits

      rule { admin | maintainer }.enable :change_commit_committer_check

      rule { commit_committer_check_available }.enable :read_commit_committer_check

      rule { ~commit_committer_check_available }.prevent :change_commit_committer_check

      rule { admin | maintainer }.enable :change_commit_committer_name_check

      rule { commit_committer_name_check_available }.enable :read_commit_committer_name_check

      rule { ~commit_committer_name_check_available }.prevent :change_commit_committer_name_check

      rule { admin | maintainer }.enable :change_reject_non_dco_commits

      rule { reject_non_dco_commits_available }.enable :read_reject_non_dco_commits

      rule { ~reject_non_dco_commits_available }.prevent :change_reject_non_dco_commits

      rule { owner | reporter | internal_access | public_project }.enable :build_read_project

      rule { ~admin & owner & owner_cannot_destroy_project }.prevent :remove_project

      rule { user_banned_from_namespace }.prevent_all

      with_scope :subject
      condition(:needs_new_sso_session) do
        ::Gitlab::Auth::GroupSaml::SsoEnforcer.access_restricted?(user: @user, resource: subject)
      end

      with_scope :subject
      condition(:ip_enforcement_prevents_access) do
        !::Gitlab::IpRestriction::Enforcer.new(subject.group).allows_current_ip? if subject.group
      end

      with_scope :global
      condition(:owner_cannot_destroy_project) do
        ::Gitlab::CurrentSettings.current_application_settings
          .default_project_deletion_protection
      end

      condition(:continuous_vulnerability_scanning_available) do
        ::Feature.enabled?(:dependency_scanning_on_advisory_ingestion)
      end

      condition(:manage_project_access_tokens_custom_roles_enabled) do
        ::Feature.enabled?(:manage_project_access_tokens, @subject.root_ancestor)
      end

      desc "Custom role on project that enables manage project access tokens"
      condition(:role_enables_manage_project_access_tokens) do
        ::Auth::MemberRoleAbilityLoader.new(
          user: @user,
          resource: project,
          ability: :manage_project_access_tokens
        ).has_ability?
      end

      condition(:archive_project_enabled) do
        ::Feature.enabled?(:archive_project, @subject.root_ancestor)
      end

      desc "Custom role on project that enables archiving projects"
      condition(:custom_role_enables_archive_projects) do
        ::Auth::MemberRoleAbilityLoader.new(
          user: @user,
          resource: @subject,
          ability: :archive_project
        ).has_ability?
      end

      rule { custom_roles_allowed & archive_project_enabled & custom_role_enables_archive_projects }.policy do
        enable :archive_project
      end

      rule { needs_new_sso_session }.policy do
        prevent :read_project
      end

      rule { ip_enforcement_prevents_access & ~admin & ~auditor }.policy do
        prevent_all
      end

      rule { locked_approvers_rules }.policy do
        prevent :modify_approvers_rules
      end

      rule { locked_merge_request_author_setting }.policy do
        prevent :modify_merge_request_author_setting
      end

      rule { locked_merge_request_committer_setting }.policy do
        prevent :modify_merge_request_committer_setting
      end

      rule { issue_analytics_enabled }.enable :read_issue_analytics

      rule { can?(:read_merge_request) & code_review_analytics_enabled }.enable :read_code_review_analytics

      rule { (admin | reporter) & dora4_analytics_available }
        .enable :read_dora4_analytics

      rule { (admin | reporter) & project_merge_request_analytics_available }
        .enable :read_project_merge_request_analytics

      rule { combined_project_analytics_dashboards_enabled }.enable :read_combined_project_analytics_dashboards

      rule { can?(:read_project) & requirements_available }.enable :read_requirement

      rule { requirements_available & (reporter | admin) }.policy do
        enable :create_requirement
        enable :create_requirement_test_report
        enable :admin_requirement
        enable :update_requirement
        enable :import_requirements
        enable :export_requirements
      end

      rule { requirements_available & (owner | admin) }.enable :destroy_requirement

      rule { quality_management_available & can?(:reporter_access) & can?(:create_issue) }.enable :create_test_case

      rule { compliance_framework_available & can?(:owner_access) }.enable :admin_compliance_framework

      rule { status_page_available & can?(:owner_access) }.enable :mark_issue_for_publication
      rule { status_page_available & can?(:developer_access) }.enable :publish_status_page

      rule { hidden }.policy do
        prevent :download_code
        prevent :build_download_code
      end

      rule { read_only }.policy do
        prevent(*readonly_abilities)

        readonly_features.each do |feature|
          prevent(*create_update_admin(feature))
        end
      end

      rule { auditor | can?(:developer_access) }.enable :add_project_to_instance_security_dashboard

      rule { (admin | maintainer) & group_merge_request_approval_settings_enabled }.policy do
        enable :admin_merge_request_approval_settings
      end

      rule { custom_roles_allowed & role_enables_read_code }.enable :read_code

      rule { custom_roles_allowed & role_enables_read_vulnerability }.policy do
        enable :access_security_and_compliance
        enable :read_vulnerability
        enable :read_security_resource
        enable :create_vulnerability_export
      end

      rule { custom_roles_allowed & role_enables_admin_merge_request }.policy do
        enable :read_merge_request
        enable :admin_merge_request
        enable :download_code # required to negate https://gitlab.com/gitlab-org/gitlab/-/blob/3061d30d9b3d6d4c4dd5abe68bc1e4a8a93c7966/app/policies/project_policy.rb#L603-607
      end

      rule { custom_roles_allowed & role_enables_admin_vulnerability }.policy do
        enable :admin_vulnerability
      end

      rule { custom_roles_allowed & role_enables_read_dependency & dependency_scanning_enabled }.policy do
        enable :access_security_and_compliance
        enable :read_dependency
      end

      rule { can?(:create_issue) & okrs_enabled }.policy do
        enable :create_objective
        enable :create_key_result
      end

      rule { suggested_reviewers_bot & suggested_reviewers_available & resource_access_token_feature_available & resource_access_token_creation_allowed }.policy do
        enable :admin_project_member
        enable :create_resource_access_tokens
      end

      rule { role_enables_manage_project_access_tokens & resource_access_token_feature_available & resource_access_token_creation_allowed & manage_project_access_tokens_custom_roles_enabled }.policy do
        enable :read_resource_access_tokens
        enable :create_resource_access_tokens
        enable :destroy_resource_access_tokens
        enable :manage_resource_access_tokens
      end

      rule { security_policy_bot }.policy do
        enable :create_pipeline
        enable :create_bot_pipeline
        enable :build_download_code
      end

      rule do
        ai_features_enabled & fill_in_merge_request_template_enabled & can?(:create_merge_request_in)
      end.enable :fill_in_merge_request_template

      rule do
        ai_features_enabled & generate_description_enabled & can?(:create_issue)
      end.enable :generate_description

      rule { target_branch_rules_enabled & target_branch_rules_available & maintainer }.policy do
        enable :admin_target_branch_rule
      end

      rule do
        target_branch_rules_enabled & target_branch_rules_available
      end.enable :read_target_branch_rule

      rule do
        (maintainer | owner | admin) & pages_multiple_versions_available
      end.enable :pages_multiple_versions

      rule { continuous_vulnerability_scanning_available & can?(:developer_access) }.policy do
        enable :enable_continuous_vulnerability_scans
      end

      rule { can?(:reporter_access) & tracing_enabled }.policy do
        enable :read_tracing
      end

      rule { can?(:reporter_access) & observability_metrics_enabled }.policy do
        enable :read_observability_metrics
      end

      rule { ci_cancellation_maintainers_only & ~can?(:maintainer_access) }.policy do
        prevent :cancel_pipeline
        prevent :cancel_build
      end

      rule { ci_cancellation_no_one }.policy do
        prevent :cancel_pipeline
        prevent :cancel_build
      end
    end

    override :lookup_access_level!
    def lookup_access_level!
      return ::Gitlab::Access::NO_ACCESS if needs_new_sso_session?
      return ::Gitlab::Access::NO_ACCESS if visual_review_bot?
      return ::Gitlab::Access::REPORTER if security_bot? && auto_fix_enabled?

      super
    end

    # Available in Core for self-managed but only paid for .com to prevent abuse
    override :resource_access_token_create_feature_available?
    def resource_access_token_create_feature_available?
      return false unless resource_access_token_feature_available?
      return super unless ::Gitlab.com?

      namespace = project.namespace
      namespace.licensed_feature_available?(:resource_access_token)
    end

    override :resource_access_token_feature_available?
    def resource_access_token_feature_available?
      return false if ::Gitlab::CurrentSettings.personal_access_tokens_disabled?

      super
    end

    override :namespace_catalog_available?
    def namespace_catalog_available?
      project.licensed_feature_available?(:ci_namespace_catalog)
    end
  end
end
