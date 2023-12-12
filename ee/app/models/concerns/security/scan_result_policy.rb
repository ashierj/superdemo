# frozen_string_literal: true

module Security
  module ScanResultPolicy
    extend ActiveSupport::Concern

    # Used for both policies and rules
    LIMIT = 5

    APPROVERS_LIMIT = 300

    SCAN_FINDING = 'scan_finding'
    LICENSE_SCANNING = 'license_scanning'
    LICENSE_FINDING = 'license_finding'
    ANY_MERGE_REQUEST = 'any_merge_request'

    REQUIRE_APPROVAL = 'require_approval'

    ALLOWED_ROLES = %w[developer maintainer owner].freeze

    included do
      has_many :scan_result_policy_reads,
        class_name: 'Security::ScanResultPolicyRead',
        foreign_key: 'security_orchestration_policy_configuration_id',
        inverse_of: :security_orchestration_policy_configuration
      has_many :approval_merge_request_rules,
        foreign_key: 'security_orchestration_policy_configuration_id',
        inverse_of: :security_orchestration_policy_configuration
      has_many :approval_project_rules,
        foreign_key: 'security_orchestration_policy_configuration_id',
        inverse_of: :security_orchestration_policy_configuration

      def delete_scan_finding_rules
        delete_in_batches(approval_merge_request_rules)
        delete_in_batches(approval_project_rules)
      end

      def delete_scan_result_policy_reads(project_id)
        scan_result_policy_reads.where(project_id: project_id).delete_all
      end

      def delete_scan_finding_rules_for_project(project_id)
        delete_in_batches(approval_project_rules.where(project_id: project_id))
        delete_in_batches(approval_merge_request_rules.for_merge_request_project(project_id))
      end

      def delete_software_license_policies(project)
        delete_in_batches(
          project
            .software_license_policies
            .where(scan_result_policy_read: scan_result_policy_reads.for_project(project))
        )
      end

      def delete_policy_violations(project)
        # scan_result_policy_violations does not store security_orchestration_policy_configuration_id
        # so we need to scope them through scan_resul_policy_reads in order to delete through policy_configuration
        delete_in_batches(
          Security::ScanResultPolicyViolation
            .where(scan_result_policy_read: scan_result_policy_reads.for_project(project))
        )
      end

      def active_scan_result_policies
        scan_result_policies&.select { |config| config[:enabled] }&.first(LIMIT)
      end

      def scan_result_policies
        policy_by_type(:scan_result_policy)
      end

      def delete_in_batches(relation)
        relation.each_batch(order_hint: :updated_at) do |batch|
          delete_batch(batch)
        end
      end

      def delete_batch(batch)
        batch.delete_all
      end
    end
  end
end
