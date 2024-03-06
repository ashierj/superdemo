# frozen_string_literal: true

module Security
  module SecurityOrchestrationPolicies
    class PolicyScopeFetcher
      def initialize(policy_scope:, container:, current_user:)
        @policy_scope = policy_scope
        @container = container
        @current_user = current_user
      end

      def execute
        return unless policy_scope_enabled?
        return result if policy_scope.blank?

        including_projects, excluding_projects = scoped_projects

        result(compliance_frameworks, including_projects, excluding_projects)
      end

      private

      attr_reader :policy_scope, :container, :current_user

      def result(compliance_frameworks = [], including_projects = [], excluding_projects = [])
        {
          compliance_frameworks: compliance_frameworks,
          including_projects: including_projects,
          excluding_projects: excluding_projects
        }
      end

      def compliance_frameworks
        compliance_framework_ids = policy_scope[:compliance_frameworks]&.pluck(:id)

        return [] if compliance_framework_ids.blank?

        root_ancestor.compliance_management_frameworks.id_in(compliance_framework_ids) || []
      end

      def scoped_projects
        included_project_ids = policy_scope.dig(:projects, :including)&.pluck(:id) || []
        excluded_project_ids = policy_scope.dig(:projects, :excluding)&.pluck(:id) || []
        project_ids = included_project_ids + excluded_project_ids

        return [[], []] if project_ids.empty?

        projects = root_ancestor.all_projects.id_in(project_ids).index_by(&:id)
        including_projects = projects.values_at(*included_project_ids).compact
        excluding_projects = projects.values_at(*excluded_project_ids).compact

        [including_projects, excluding_projects]
      end

      def root_ancestor
        if container.is_a?(ComplianceManagement::Framework)
          container.namespace
        else
          container.root_ancestor
        end
      end

      def group
        return container if container.is_a?(Namespace)

        container.namespace
      end

      def policy_scope_enabled?
        return false unless group && group.namespace_settings

        Feature.enabled?(:security_policies_policy_scope, group) &&
          group.namespace_settings&.toggle_security_policies_policy_scope?
      end
    end
  end
end
