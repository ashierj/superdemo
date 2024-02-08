# frozen_string_literal: true

module EE
  module BranchRules
    module DestroyService
      extend ::Gitlab::Utils::Override

      # rubocop:disable Cop/AvoidReturnFromBlocks -- The overriden `execute`
      # method yields and then raises an error. We use `return` here to exit
      # the super method. If we used break it would break out of the block and
      # continue execution of the super method causing the error to be raised.
      override :execute
      def execute
        super do
          case branch_rule
          when ::Projects::AllBranchesRule
            return destroy_all_branches_rule
          when ::Projects::AllProtectedBranchesRule
            return destroy_all_protected_branches_rule
          end
        end
      end
      # rubocop:enable Cop/AvoidReturnFromBlocks

      private

      def destroy_all_branches_rule
        response = destroy_approval_project_rules

        return response if response.error?

        destroy_external_status_checks
      end

      def destroy_all_protected_branches_rule
        destroy_approval_project_rules
      end

      def destroy_approval_project_rules
        errors = approval_project_rules.find_each.each_with_object([]) do |rule, error_accumulator|
          response = ::ApprovalRules::ProjectRuleDestroyService.new(rule, current_user).execute

          error_accumulator << response if response[:status] == :error
        end

        return ::ServiceResponse.success if errors.blank?

        ::ServiceResponse.error(message: "Failed to delete approval #{'rule'.pluralize(errors.count)}.")
      end

      def destroy_external_status_checks
        errors = external_status_checks.find_each.each_with_object([]) do |check, error_accumulator|
          response = ::ExternalStatusChecks::DestroyService.new(
            container: project, current_user: current_user
          ).execute(check)

          error_accumulator << response if response[:status] == :error
        end

        return ::ServiceResponse.success if errors.blank?

        ::ServiceResponse.error(message: "Failed to delete external status #{'check'.pluralize(errors.count)}.")
      end
    end
  end
end
