# frozen_string_literal: true

module EE
  module ProtectedBranches
    module RenamingBlockedByPolicy
      def execute(protected_branch)
        raise ::Gitlab::Access::AccessDeniedError if renaming? && blocked?(protected_branch.project)

        super
      end

      private

      def renaming?
        params.key?(:name)
      end

      def blocked?(project)
        return false unless project&.licensed_feature_available?(:security_orchestration_policies)
        return false unless ::Feature.enabled?(:scan_result_policies_block_unprotecting_branches, project)

        project.scan_result_policy_reads.blocking_branch_modification.exists?
      end
    end
  end
end
