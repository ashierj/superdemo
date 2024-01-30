# frozen_string_literal: true

module EE
  module Projects
    module BranchRule
      extend Forwardable

      def_delegators(:protected_branch, :external_status_checks)

      def approval_project_rules
        protected_branch.approval_project_rules_with_unique_policies
      end
    end
  end
end
