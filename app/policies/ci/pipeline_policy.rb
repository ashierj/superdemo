# frozen_string_literal: true

module Ci
  class PipelinePolicy < BasePolicy
    delegate { @subject.project }

    condition(:protected_ref) { ref_protected?(@user, @subject.project, @subject.tag?, @subject.ref) }

    condition(:branch_allows_collaboration) do
      @subject.project.branch_allows_collaboration?(@user, @subject.ref)
    end

    condition(:external_pipeline, scope: :subject, score: 0) do
      @subject.external?
    end

    # Disallow users without permissions from accessing internal pipelines
    rule { ~can?(:read_build) & ~external_pipeline }.policy do
      prevent :read_pipeline
    end

    rule { protected_ref }.prevent :update_pipeline

    rule { can?(:public_access) & branch_allows_collaboration }.policy do
      enable :update_pipeline
    end

    def ref_protected?(user, project, tag, ref)
      access = ::Gitlab::UserAccess.new(user, project: project)

      if tag
        !access.can_create_tag?(ref)
      else
        !access.can_update_branch?(ref)
      end
    end
  end
end
