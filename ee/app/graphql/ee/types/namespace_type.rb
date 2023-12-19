# frozen_string_literal: true

module EE
  module Types
    module NamespaceType
      extend ActiveSupport::Concern

      prepended do
        field :add_on_eligible_users,
          ::Types::GitlabSubscriptions::AddOnUserType.connection_type,
          null: true,
          description: 'Users in the namespace hierarchy that add ons are applicable for. This only applies to ' \
                       'root namespaces.',
          resolver: ::Resolvers::GitlabSubscriptions::AddOnEligibleUsersResolver,
          alpha: { milestone: '16.5' }

        field :add_on_purchase,
          ::Types::GitlabSubscriptions::AddOnPurchaseType,
          null: true,
          description: 'AddOnPurchase associated with the namespace',
          resolver: ::Resolvers::GitlabSubscriptions::Namespaces::AddOnPurchaseResolver,
          authorize: :read_namespace_via_membership

        field :additional_purchased_storage_size,
              GraphQL::Types::Float,
              null: true,
              description: 'Additional storage purchased for the root namespace in bytes.',
              authorize: :read_namespace_via_membership

        field :total_repository_size_excess,
              GraphQL::Types::Float,
              null: true,
              description: 'Total excess repository size of all projects in the root namespace in bytes. ' \
                           'This only applies to namespaces under Project limit enforcement.',
              authorize: :read_namespace_via_membership

        field :total_repository_size,
              GraphQL::Types::Float,
              null: true,
              description: 'Total repository size of all projects in the root namespace in bytes.',
              authorize: :read_namespace_via_membership

        field :contains_locked_projects,
              GraphQL::Types::Boolean,
              null: true,
              description: 'Includes at least one project where the repository size exceeds the limit. ' \
                           'This only applies to namespaces under Project limit enforcement.',
              method: :contains_locked_projects?,
              authorize: :read_namespace_via_membership

        field :repository_size_excess_project_count,
              GraphQL::Types::Int,
              null: true,
              description: 'Number of projects in the root namespace where the repository size exceeds the limit. ' \
                           'This only applies to namespaces under Project limit enforcement.',
              authorize: :read_namespace_via_membership

        field :actual_repository_size_limit,
              GraphQL::Types::Float,
              null: true,
              description: 'Size limit for repositories in the namespace in bytes. ' \
                           'This limit only applies to namespaces under Project limit enforcement.',
              authorize: :read_namespace_via_membership

        field :actual_size_limit,
              GraphQL::Types::Float,
              null: true,
              description: 'The actual storage size limit (in bytes) based on the enforcement type ' \
                           'of either repository or namespace. This limit is agnostic of enforcement type.',
              authorize: :read_namespace_via_membership

        field :storage_size_limit,
              GraphQL::Types::Float,
              null: true,
              description: 'The storage limit (in bytes) included with the root namespace plan. ' \
                           'This limit only applies to namespaces under namespace limit enforcement.',
              authorize: :read_namespace_via_membership

        field :is_temporary_storage_increase_enabled,
              GraphQL::Types::Boolean,
              null: true,
              description: 'Status of the temporary storage increase.',
              deprecated: {
                reason: 'Feature removal, will be completely removed in 17.0',
                milestone: '16.7'
              },
              method: :temporary_storage_increase_enabled?,
              authorize: :read_namespace_via_membership

        field :temporary_storage_increase_ends_on,
              ::Types::TimeType,
              null: true,
              description: 'Date until the temporary storage increase is active.',
              deprecated: {
                reason: 'Feature removal, will be completely removed in 17.0',
                milestone: '16.7'
              },
              authorize: :read_namespace_via_membership

        field :compliance_frameworks,
              ::Types::ComplianceManagement::ComplianceFrameworkType.connection_type,
              null: true,
              description: 'Compliance frameworks available to projects in this namespace.',
              resolver: ::Resolvers::ComplianceManagement::FrameworkResolver,
              authorize: :read_namespace_via_membership

        field :scan_execution_policies,
              ::Types::SecurityOrchestration::ScanExecutionPolicyType.connection_type,
              calls_gitaly: true,
              null: true,
              description: 'Scan Execution Policies of the namespace.',
              resolver: ::Resolvers::SecurityOrchestration::ScanExecutionPolicyResolver

        field :scan_result_policies,
              ::Types::SecurityOrchestration::ScanResultPolicyType.connection_type,
              calls_gitaly: true,
              null: true,
              description: 'Scan Result Policies of the project',
              resolver: ::Resolvers::SecurityOrchestration::ScanResultPolicyResolver

        def additional_purchased_storage_size
          object.additional_purchased_storage_size.megabytes
        end

        def storage_size_limit
          object.root_ancestor.actual_plan.actual_limits.storage_size_limit.megabytes
        end
      end
    end
  end
end
