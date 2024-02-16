# frozen_string_literal: true

module EE
  module BranchRules
    module UpdateService
      extend ::Gitlab::Utils::Override

      # rubocop:disable Cop/AvoidReturnFromBlocks -- see similar
      # implementation and explanation in BranchRules::DestroyService
      override :execute
      def execute(skip_authorization: false)
        super do
          case branch_rule
          when ::Projects::AllBranchesRule
            return ServiceResponse.error(message: 'All branch rules cannot be updated')
          when ::Projects::AllProtectedBranchesRule
            return ServiceResponse.error(message: 'All protected branch rules cannot be updated')
          end
        end
      end
      # rubocop:enable Cop/AvoidReturnFromBlocks
    end
  end
end
