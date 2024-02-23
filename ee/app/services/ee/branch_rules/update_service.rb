# frozen_string_literal: true

module EE
  module BranchRules
    module UpdateService
      def execute_on_all_branches_rule
        ServiceResponse.error(message: 'All branch rules cannot be updated')
      end

      def execute_on_all_protected_branches_rule
        ServiceResponse.error(message: 'All protected branch rules cannot be updated')
      end
    end
  end
end
