# frozen_string_literal: true

module Security
  module ScanResultPolicies
    class DetailedPolicyViolationComment < PolicyViolationComment
      include Gitlab::Utils::StrongMemoize

      MORE_VIOLATIONS_DETECTED = 'More violations have been detected in addition to the list above.'
      VIOLATIONS_BLOCKING_TITLE = ':warning: **Violations blocking this merge request**'
      VIOLATIONS_DETECTED_TITLE = ':warning: **Violations detected in this merge request**'

      private

      def body_message
        return super if ::Feature.disabled?(:save_policy_violation_data, project)
        return fixed_note_body if reports.empty?

        summary = <<~MARKDOWN
        #{reports_header}
        #{merge_request.author.name}, this merge request has policy violations and errors.
        #{only_optional_approvals? ? '' : "**To unblock this merge request, fix these items:**\n"}
        #{violation_summary}

        #{
          if only_optional_approvals?
            'Consider including optional reviewers based on the policy rules in the MR widget.'
          else
            "If you think these items shouldn't be violations, ask eligible approvers of each policy to approve this merge request."
          end
        }

        #{
          if [newly_introduced_violations, previously_existing_violations, any_merge_request_commits].any?(&:present?)
            only_optional_approvals? ? VIOLATIONS_DETECTED_TITLE : VIOLATIONS_BLOCKING_TITLE
          else
            ''
          end
        }
        MARKDOWN

        [
          summary,
          newly_introduced_violations,
          previously_existing_violations,
          any_merge_request_commits,
          license_scanning_violations,
          error_messages
        ].compact.join("\n")
      end

      def details
        ::Security::ScanResultPolicies::PolicyViolationDetails.new(merge_request)
      end
      strong_memoize_attr :details

      def violation_summary
        all_policies = details.unique_policy_names
        any_merge_request_policies = details.unique_policy_names(:any_merge_request)
        license_scanning_policies = details.unique_policy_names(:license_scanning)
        errors = details.errors
        summary = ["Resolve all violations in the following merge request approval policies" \
                   "#{all_policies.present? ? ": #{all_policies.join(', ')}." : '.'}"]

        if any_merge_request_policies.present?
          summary << "Acquire approvals from eligible approvers defined in the following " \
                     "merge request approval policies: #{any_merge_request_policies.join(', ')}."
        end

        if license_scanning_policies.present? && license_scanning_violations.present?
          summary << ("Remove all denied licenses identified by the following merge request approval policies: " \
            "#{license_scanning_policies.join(', ')}")
        end

        summary << 'Resolve the errors and re-run the pipeline.' if errors.present?

        summary.map { |list_item| "- #{list_item}" }.join("\n")
      end

      def newly_introduced_violations
        scan_finding_violations(details.new_scan_finding_violations, 'This merge request introduces these violations')
      end
      strong_memoize_attr :newly_introduced_violations

      def previously_existing_violations
        scan_finding_violations(details.previous_scan_finding_violations, 'Previously existing vulnerabilities')
      end
      strong_memoize_attr :previously_existing_violations

      def scan_finding_violations(violations, title)
        list = violations.map do |violation|
          build_scan_finding_violation_line(violation)
        end
        return if list.empty?

        <<~MARKDOWN
        ---

        #{title}:

        #{violations_list(list)}
        MARKDOWN
      end

      def license_scanning_violations
        list = details.license_scanning_violations.map do |violation|
          dependencies = violation.dependencies
          "1. #{violation.url.present? ? "[#{violation.license}](#{violation.url})" : violation.license}: " \
            "Used by #{dependencies.first(Security::ScanResultPolicyViolation::MAX_VIOLATIONS).join(', ')}" \
            "#{dependencies.size > Security::ScanResultPolicyViolation::MAX_VIOLATIONS ? ', …and more' : ''}"
        end
        return if list.empty?

        <<~MARKDOWN
        :warning: **Out-of-policy licenses:**

        #{violations_list(list)}
        MARKDOWN
      end

      def build_scan_finding_violation_line(violation)
        line = "1."
        line += " #{violation.severity.capitalize} **·**" if violation.severity
        line += " #{violation.name}" if violation.name

        if violation.path.present?
          location = violation.location
          start_line = location[:start_line]
          line += " **·** [#{start_line.present? ? "Line #{start_line} " : ''}#{location[:file]}](#{violation.path})"
        end

        line += " (#{violation.report_type.humanize})" if violation.report_type
        line
      end

      def any_merge_request_commits
        list = details.any_merge_request_violations.flat_map do |violation|
          next unless violation.commits.is_a?(Array)

          violation.commits.map { |commit| "1. `#{commit}`" }
        end.compact
        return if list.empty?

        <<~MARKDOWN
        ---

        Unsigned commits:

        #{violations_list(list)}
        MARKDOWN
      end
      strong_memoize_attr :any_merge_request_commits

      def violations_list(list)
        [
          list.first(Security::ScanResultPolicyViolation::MAX_VIOLATIONS).join("\n"),
          list.size > Security::ScanResultPolicyViolation::MAX_VIOLATIONS ? "\n#{MORE_VIOLATIONS_DETECTED}" : nil
        ].compact.join("\n")
      end

      def error_messages
        errors = details.errors
        return if errors.blank?

        <<~MARKDOWN
        :exclamation: **Errors**

        #{errors.map { |error| "- #{error.message}" }.join("\n")}
        MARKDOWN
      end
    end
  end
end
