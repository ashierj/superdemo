# frozen_string_literal: true

module Security
  class SyncLicenseScanningRulesService
    include ::Gitlab::Utils::StrongMemoize
    include ::Security::ScanResultPolicies::PolicyViolationCommentGenerator

    def self.execute(pipeline)
      new(pipeline).execute
    end

    def initialize(pipeline)
      @pipeline = pipeline
      @scanner = ::Gitlab::LicenseScanning.scanner_for_pipeline(project, pipeline)
    end

    def execute
      return unless scanner.results_available?

      merge_requests = pipeline.merge_requests_as_head_pipeline.not_merged

      sync_license_finding_rules(merge_requests)
    end

    private

    attr_reader :pipeline, :scanner

    delegate :project, to: :pipeline

    def sync_license_finding_rules(merge_requests)
      merge_requests.each do |merge_request|
        remove_required_license_finding_approval(merge_request)
      end
    end

    def remove_required_license_finding_approval(merge_request)
      license_approval_rules = merge_request
                                 .approval_rules
                                 .report_approver
                                 .license_scanning
                                 .with_scan_result_policy_read
                                 .including_scan_result_policy_read

      return if license_approval_rules.empty?

      violations = Security::SecurityOrchestrationPolicies::UpdateViolationsService.new(merge_request,
        :license_scanning)
      violated_rules, unviolated_rules = license_approval_rules.partition do |rule|
        violates_policy?(merge_request, rule, violations)
      end

      update_required_approvals(merge_request, violated_rules, unviolated_rules)
      log_violated_rules(merge_request, violated_rules)
      violations.add(violated_rules.pluck(:scan_result_policy_id), unviolated_rules.pluck(:scan_result_policy_id)) # rubocop:disable CodeReuse/ActiveRecord
      violations.execute
      generate_policy_bot_comment(
        merge_request,
        license_approval_rules.applicable_to_branch(merge_request.target_branch),
        :license_scanning)
    end

    def update_required_approvals(merge_request, violated_rules, unviolated_rules)
      merge_request.reset_required_approvals(violated_rules)
      ApprovalMergeRequestRule.remove_required_approved(unviolated_rules)
    end

    ## Checks if a policy rule violates the following conditions:
    ##   - If license_states has `newly_detected`, check for newly detected dependency
    ##     with license type violating the policy.
    ##   - If match_on_inclusion_license is false, any detected licenses that does not match
    ##     the licenses from `license_types` should require approval
    def violates_policy?(merge_request, rule, violations)
      scan_result_policy_read = rule.scan_result_policy_read
      target_branch_report = target_branch_report(merge_request)

      license_policies = license_policies(scan_result_policy_read)
      license_ids_from_policy, license_names_from_policy = license_policy_ids_and_names(license_policies)
      licenses_from_policy = join_ids_and_names(license_ids_from_policy, license_names_from_policy)

      license_ids, license_names = licenses_to_check(target_branch_report, scan_result_policy_read)

      if scan_result_policy_read.match_on_inclusion_license
        all_denied_licenses = licenses_from_policy
        policy_denied_license_names = (all_denied_licenses & licenses_from_report) - license_ids_from_policy
        violates_license_policy = report.violates_for_licenses?(license_policies, license_ids, license_names)
      else
        # when match_on_inclusion_license is false, only the licenses mentioned in the policy are allowed
        all_denied_licenses = (licenses_from_report - licenses_from_policy).uniq
        comparison_licenses = join_ids_and_names(license_ids, license_names)
        policy_denied_license_names = (comparison_licenses - licenses_from_policy).uniq - license_ids
        violates_license_policy = policy_denied_license_names.present?
      end

      # when there are no license violations, but new dependency with policy licenses is added, require approval
      if scan_result_policy_read.newly_detected?
        new_license_dependency_map = new_dependencies_with_denied_licenses(target_branch_report, all_denied_licenses)
        if new_license_dependency_map.present?
          violates_license_policy = true
          policy_denied_license_names = new_license_dependency_map.keys.uniq
        end
      end

      save_violation_data(violations, rule, policy_denied_license_names) if violates_license_policy
      violates_license_policy
    end

    def license_policies(scan_result_policy_read)
      project
        .software_license_policies
        .including_license
        .for_scan_result_policy_read(scan_result_policy_read.id)
    end

    def licenses_to_check(target_branch_report, scan_result_policy_read)
      only_newly_detected = scan_result_policy_read.license_states == [ApprovalProjectRule::NEWLY_DETECTED]

      if only_newly_detected
        diff = target_branch_report.diff_with(report)
        license_names = diff[:added].map(&:name)
        license_ids = diff[:added].filter_map(&:id)
      elsif scan_result_policy_read.newly_detected?
        license_names = report.license_names
        license_ids = report.licenses.filter_map(&:id)
      else
        license_names = target_branch_report.license_names
        license_ids = target_branch_report.licenses.filter_map(&:id)
      end

      [license_ids, license_names]
    end

    def license_policy_ids_and_names(license_policies)
      ids = license_policies.map(&:spdx_identifier)
      names = license_policies.map(&:name)

      [ids, names].map(&:compact)
    end

    def join_ids_and_names(ids, names)
      (ids + names).compact.uniq
    end

    def new_dependencies_with_denied_licenses(target_branch_report, denied_licenses)
      new_dependency_names_in_report = new_dependency_names(target_branch_report)

      report.licenses
            .select { |license| denied_licenses.include?(license.name) || denied_licenses.include?(license.id) }
            .to_h { |license| [license.name, license.dependencies.map(&:name)] }
            .select { |_license, dependency_names| (dependency_names & new_dependency_names_in_report).present? }
    end

    def target_branch_report(merge_request)
      ::Gitlab::LicenseScanning.scanner_for_pipeline(project, target_branch_pipeline(merge_request)).report
    end

    def target_branch_pipeline(merge_request)
      merge_request.latest_comparison_pipeline_with_sbom_reports
    end

    def new_dependency_names(target_branch_report)
      report.dependency_names - target_branch_report.dependency_names
    end

    def report
      scanner.report
    end
    strong_memoize_attr :report

    def licenses_from_report
      report.license_names.concat(report.licenses.filter_map(&:id)).compact.uniq
    end
    strong_memoize_attr :licenses_from_report

    def log_violated_rules(merge_request, rules)
      return unless rules.any?

      rules.each do |approval_rule|
        log_update_approval_rule(
          merge_request,
          approval_rule_id: approval_rule.id,
          approval_rule_name: approval_rule.name
        )
      end
    end

    def log_update_approval_rule(merge_request, **attributes)
      default_attributes = {
        reason: 'license_finding rule violated',
        event: 'update_approvals',
        merge_request_id: merge_request.id,
        merge_request_iid: merge_request.iid,
        project_path: project.full_path
      }
      Gitlab::AppJsonLogger.info(message: 'Updating MR approval rule', **default_attributes.merge(attributes))
    end

    def save_violation_data(violations, rule, policy_denied_licenses)
      return if policy_denied_licenses.blank?

      violations.add_violation(rule.scan_result_policy_id, policy_denied_licenses)
    end
  end
end
